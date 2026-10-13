#!/system/bin/sh
########################################
# Cepheus Game Booster (service.sh) v2.0
# Combined module: GPU floor + I/O + VM +
# thermal throttle release (IN-GAME ONLY).
#
# Thermal: when a game is detected, the
# userspace daemon mi_thermald is paused
# (SIGSTOP), then cooling devices and the
# CPU frequency clamp are cleared so the
# big/prime cores are not pinned to
# ~1.28-1.49GHz at a 44-48C skin temp.
# When the game is closed, the daemon is
# resumed (normal thermal again). Kernel
# protection (lmh-dcvs 85C, pop-mem 95C,
# cpu-step 110C) stays active.
#
# Does not touch Encore Tweaks' domain
# (CPU governor/cpufreq/schedtune are
# handled by Encore); game state is read
# read-only from Encore.
########################################

MODDIR=${MODDIR:-$(dirname "$0")}
CONF="$MODDIR/tweak.conf"
LOG="$MODDIR/tweak.log"

log() { echo "[cepheus-booster] $*" >>"$LOG"; }

read_opt() {
	local v
	v=$(sed -n "s/^$1=//p" "$CONF" 2>/dev/null | head -n1 | tr -d ' \r')
	[ -n "$v" ] && echo "$v" || echo "$2"
}

# wait until boot fully completes
n=0
while [ -z "$(getprop sys.boot_completed)" ]; do
	sleep 5
	n=$((n + 1))
	[ $n -gt 150 ] && break
done
sleep 10

: >"$LOG"
log "started v2.0"

EN_IO=$(read_opt GP_IO true)
EN_VM=$(read_opt GP_VM true)
EN_GPU=$(read_opt GP_GPU true)
EN_THERMAL=$(read_opt GP_THERMAL true)
GP_DYN=$(read_opt GP_DYNAMIC true)
GPU_GAME_FLOOR=$(read_opt GPU_GAME_PWRLEVEL 4)
GPU_IDLE_FLOOR=$(read_opt GPU_IDLE_PWRLEVEL 6)
IO_SCHED=$(read_opt IO_SCHED deadline)
VM_VFS=$(read_opt VM_VFS_CACHE_PRESSURE 60)
VM_DWC=$(read_opt VM_DIRTY_WRITEBACK_CS 1000)
THERMAL_DAEMONS=$(read_opt THERMAL_DAEMONS mi_thermald)

G=/sys/class/kgsl/kgsl-3d0
GAMELIST=/data/adb/.config/encore/gamelist.json
GAMEINFO=/data/adb/.config/encore/gameinfo

gpu_floor() { echo "$1" >"$G/min_pwrlevel" 2>/dev/null; }

fg_pkg() {
	dumpsys window 2>/dev/null \
		| sed -n 's/.*mCurrentFocus=[^ ]* u[0-9]* \([a-zA-Z0-9_.]*\)\/.*/\1/p' \
		| head -n1
}

game_active() {
	local p pid fg
	# signal 1: game state from Encore (read-only) + process liveness check
	if [ -r "$GAMEINFO" ]; then
		read -r p pid _ <"$GAMEINFO" 2>/dev/null
		if [ -n "$p" ] && [ "$p" != "NULL" ]; then
			if [ -z "$pid" ] || [ -d "/proc/$pid" ]; then return 0; fi
		fi
	fi
	# signal 2: foreground app is in Encore's game list
	if [ -r "$GAMELIST" ]; then
		fg=$(fg_pkg)
		[ -n "$fg" ] && grep -q "\"$fg\"" "$GAMELIST" 2>/dev/null && return 0
	fi
	return 1
}

# ---------- thermal helpers ----------
unlock_cpu() {
	local p
	for p in /sys/devices/system/cpu/cpufreq/policy*; do
		[ -f "$p/cpuinfo_max_freq" ] || continue
		cat "$p/cpuinfo_max_freq" >"$p/scaling_max_freq" 2>/dev/null
	done
}

reset_cooling() {
	local c t
	for c in /sys/class/thermal/cooling_device*; do
		t=$(cat "$c/type" 2>/dev/null)
		case "$t" in
		thermal-cpufreq-* | thermal-devfreq-*) echo 0 >"$c/cur_state" 2>/dev/null ;;
		esac
	done
}

stop_daemons() {
	local d pid
	for d in $THERMAL_DAEMONS; do
		pid=$(pidof "$d" 2>/dev/null)
		[ -n "$pid" ] && kill -STOP $pid 2>/dev/null
	done
}

cont_daemons() {
	local d pid
	for d in $THERMAL_DAEMONS; do
		pid=$(pidof "$d" 2>/dev/null)
		[ -n "$pid" ] && kill -CONT $pid 2>/dev/null
	done
}

daemon_sig() {
	local d pid s=""
	for d in $THERMAL_DAEMONS; do
		pid=$(pidof "$d" 2>/dev/null)
		s="$s$d:${pid:-x};"
	done
	echo "$s"
}

# ---------- I/O (static, safe at all times) ----------
if [ "$EN_IO" = "true" ]; then
	for d in /sys/block/sd* /sys/block/mmcblk*; do
		[ -e "$d/queue/scheduler" ] || continue
		if grep -q "$IO_SCHED" "$d/queue/scheduler" 2>/dev/null; then
			echo "$IO_SCHED" >"$d/queue/scheduler" && log "io: $(basename "$d") scheduler -> $IO_SCHED"
		fi
	done
fi

# ---------- VM (static) ----------
if [ "$EN_VM" = "true" ]; then
	[ -w /proc/sys/vm/vfs_cache_pressure ] && echo "$VM_VFS" >/proc/sys/vm/vfs_cache_pressure && log "vm: vfs_cache_pressure -> $VM_VFS"
	[ -w /proc/sys/vm/dirty_writeback_centisecs ] && echo "$VM_DWC" >/proc/sys/vm/dirty_writeback_centisecs && log "vm: dirty_writeback_centisecs -> $VM_DWC"
fi

# ---------- GPU governor ----------
if [ "$EN_GPU" = "true" ] && [ -w "$G/devfreq/governor" ]; then
	echo msm-adreno-tz >"$G/devfreq/governor" 2>/dev/null && log "gpu: governor -> msm-adreno-tz"
fi

# ---------- static mode (no game detection) ----------
if [ "$GP_DYN" != "true" ]; then
	[ "$EN_GPU" = "true" ] && gpu_floor "$GPU_GAME_FLOOR"
	if [ "$EN_THERMAL" = "true" ]; then
		stop_daemons
		reset_cooling
		unlock_cpu
		log "thermal: static unlock (daemon '$THERMAL_DAEMONS' paused)"
	fi
	log "static mode applied"
	exit 0
fi

# ---------- dynamic mode ----------
# start from idle state
if [ "$EN_GPU" = "true" ] && [ "$(cat "$G/min_pwrlevel" 2>/dev/null)" != "$GPU_IDLE_FLOOR" ]; then
	gpu_floor "$GPU_IDLE_FLOOR"
fi
state=idle
last_sig=""
log "dynamic: game floor=$GPU_GAME_FLOOR idle floor=$GPU_IDLE_FLOOR thermal=$EN_THERMAL daemon='$THERMAL_DAEMONS'"

while true; do
	if game_active; then
		if [ "$state" != "game" ]; then
			state=game
			[ "$EN_GPU" = "true" ] && gpu_floor "$GPU_GAME_FLOOR"
			last_sig=""
			log "game: entered"
		fi
		if [ "$EN_THERMAL" = "true" ]; then
			# idempotent: keep the daemon paused at all times
			stop_daemons
			cur_sig=$(daemon_sig)
			if [ "$cur_sig" != "$last_sig" ]; then
				reset_cooling
				unlock_cpu
				last_sig="$cur_sig"
				log "game: thermal unlocked (daemon stopped + cooling reset + cpu unpinned)"
			fi
		fi
	else
		if [ "$state" != "idle" ]; then
			state=idle
			[ "$EN_GPU" = "true" ] && gpu_floor "$GPU_IDLE_FLOOR"
			[ "$EN_THERMAL" = "true" ] && cont_daemons
			log "game: exited (thermal back to normal)"
		fi
	fi
	sleep 3
done
