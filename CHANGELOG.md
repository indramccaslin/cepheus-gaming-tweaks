# Changelog

## v3.2.6 (versionCode 30026)
- **Standalone** — no longer needs Encore Tweaks or any other daemon.
- **WebUI** (KernelSU-Next Manager) to manage the game list. Fixed the app picker: `ksu.exec()` (sync) only returns the *last* line, so the WebUI now uses `ksu.listPackages()` for the app list and reads the multi-line `gamelist.txt` in a single-line-safe way.
- **CPU max lock**: all three clusters pinned to `performance` + `scaling_min = scaling_max = cpuinfo_max_freq` while a game is in foreground.
- **GPU lock at 770 MHz**: pins `min_freq = max_freq = max_gpuclk` and `min_pwrlevel = 0` during games (`GPU_GAME_LOCK`).
- **Thermal unlock**: stops `mi_thermald` + opens `thermal_message/cpu_limits` and the GPU cooling clamp during games; restored on idle.
- **Bypass charging**: keeps the phone powered by the adapter (battery `current_now ≈ 0`, cooler) while gaming.
- **Scheduler / input boost / schedtune** tuning for stable 60 fps.
- **Boot-safe**: runs via `service.sh` with a boot-count failsafe (auto-disables after repeated failed boots).
- Config `GP_POLL` (game detection interval, default 2 s).

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
