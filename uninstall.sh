#!/system/bin/sh
########################################
# Cepheus Gaming Tweaks (uninstall.sh) v3.1.1
#
# Kembalikan semua yang diubah modul ke nilai wajar/stok:
#   - CPU governor -> schedutil, batas frekuensi -> stok
#   - sched_boost=0, schedtune.boost=0
#   - GPU min_pwrlevel=6, governor msm-adreno-tz, force_* =0
#   - hidupkan mi_thermald & thermal-engine
########################################

for p in policy0 policy4 policy7; do
	base=/sys/devices/system/cpu/cpufreq/$p
	echo schedutil > "$base/scaling_governor" 2>/dev/null
	[ -w "$base/scaling_max_freq" ] && cat "$base/cpuinfo_max_freq" > "$base/scaling_max_freq" 2>/dev/null
	[ -w "$base/scaling_min_freq" ] && cat "$base/cpuinfo_min_freq" > "$base/scaling_min_freq" 2>/dev/null
done

echo 0 > /proc/sys/kernel/sched_boost 2>/dev/null
echo 0 > /dev/stune/top-app/schedtune.boost 2>/dev/null

CB=/sys/module/cpu_boost/parameters
[ -w "$CB/input_boost_ms" ] && echo 120 > "$CB/input_boost_ms" 2>/dev/null
[ -w "$CB/sched_boost_on_input" ] && echo 0 > "$CB/sched_boost_on_input" 2>/dev/null

G=/sys/class/kgsl/kgsl-3d0
echo 6 > "$G/min_pwrlevel" 2>/dev/null
echo msm-adreno-tz > "$G/devfreq/governor" 2>/dev/null
echo 675000000 > "$G/devfreq/max_freq" 2>/dev/null
for f in force_clk_on force_bus_on force_rail_on; do echo 0 > "$G/$f" 2>/dev/null; done

# pastikan pengisian baterai kembali normal (matikan bypass charging)
echo 1 > /sys/class/power_supply/battery/charging_enabled 2>/dev/null
echo 0 > /sys/class/power_supply/battery/input_suspend 2>/dev/null

start mi_thermald 2>/dev/null
start vendor.thermal-engine 2>/dev/null
