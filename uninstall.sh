#!/system/bin/sh
# Make sure the thermal daemon is not left paused when uninstalling
for d in mi_thermald; do
	pid=$(pidof "$d" 2>/dev/null)
	[ -n "$pid" ] && kill -CONT $pid 2>/dev/null
done
