# Changelog

## v2.0.0 (versionCode 3)
- **Merged** `cepheus-thermal-nolimits` + `cepheus-gaming-tweaks` into a single module.
- **Dynamic thermal**: userspace thermal throttling is released *only during games* — the `mi_thermald` daemon is `SIGSTOP`-ed, cooling devices are reset, and the CPU `scaling_max_freq` clamp is opened. Once the game is closed, the daemon is resumed (normal thermal again).
- Guard: if the daemon is restarted by the system during a game, it is paused again automatically.
- Dynamic GPU floor (game 4 / idle 6), I/O `deadline`, VM cache pressure & dirty writeback.
- Added `update.json` for the KernelSU update checker.

## v1.1.0 (versionCode 2)
- Dynamic GPU floor based on Encore's game state.
- I/O scheduler + VM tweaks.

## v1.0.0 (versionCode 1)
- Initial release: static GPU floor, I/O, VM.
