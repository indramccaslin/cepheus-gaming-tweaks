#!/system/bin/sh
# Pastikan daemon thermal tidak tertinggal dalam keadaan pause saat uninstall
for d in mi_thermald; do
	pid=$(pidof "$d" 2>/dev/null)
	[ -n "$pid" ] && kill -CONT $pid 2>/dev/null
done
