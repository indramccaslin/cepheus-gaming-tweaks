# Changelog

## v2.0.0 (versionCode 3)
- **Gabung** module `cepheus-thermal-nolimits` + `cepheus-gaming-tweaks` menjadi satu module.
- **Thermal dinamis**: throttle thermal userspace dilepas *hanya saat game* — daemon `mi_thermald` di-`SIGSTOP`, cooling-device di-reset, dan clamp `scaling_max_freq` CPU dibuka. Begitu game ditutup, daemon di-resume (thermal normal lagi).
- Guard: jika daemon di-restart sistem saat game, otomatis di-pause ulang.
- GPU floor dinamis (game 4 / idle 6), I/O `deadline`, VM cache pressure & dirty writeback.
- Ditambah `update.json` untuk cek update KernelSU.

## v1.1.0 (versionCode 2)
- GPU floor dinamis berdasarkan status game Encore.
- I/O scheduler + VM tweaks.

## v1.0.0 (versionCode 1)
- Rilis awal: GPU floor statis, I/O, VM.
