# Cepheus Game Booster

A **KernelSU / Magisk** module for smooth game FPS on **Xiaomi Mi 9 (cepheus, sm8150)**.

It bundles a thermal throttle release with GPU/I/O/VM tweaks in a single module, and
**all heavy tweaks only run while a game is in the foreground**. Outside games, the
system runs normally.

## Features

- **In-game thermal throttle release** — `mi_thermald` (Xiaomi's userspace thermal
  daemon) caps the big/prime cores to ~1.28–1.49 GHz once the skin temp
  (`quiet_therm`) reaches 44–48 °C. This module pauses that daemon during games, so
  the CPU is freed again (2.42 / 2.84 GHz) and FPS stops dropping during heavy
  fights.
- **Dynamic GPU floor** — raises the GPU floor during games for steadier frame
  pacing.
- **I/O `deadline`** + **VM tuning** (vfs_cache_pressure, dirty_writeback).
- **Safe alongside Encore Tweaks** — Encore still owns CPU governor/cpufreq/
  schedtune; this module never touches them. Game state is read read-only from
  Encore.

## How the thermal release works

1. When a game is active:
   - `kill -STOP` the thermal daemon (`THERMAL_DAEMONS`, default `mi_thermald`).
   - Reset `cooling_device` (`thermal-cpufreq-*`, `thermal-devfreq-*`) to 0.
   - Open the CPU `scaling_max_freq` clamp back to `cpuinfo_max_freq`.
2. When the game is closed: `kill -CONT` → normal thermal again.
3. Guard: if the daemon is restarted by the system during a game, it is paused
   again automatically.

> **Kernel** protection stays active (lmh-dcvs ~85 °C, pop-mem/cpu-step 95–110 °C,
> thermal HAL). Extreme heat is still handled by the kernel; only the "mild heat"
> limit (44–48 °C) from userspace is released during games.

## Installation

KernelSU Next / KernelSU Manager:
1. Download `cepheus-gaming-tweaks-vX.Y.Z.zip` from [Releases](../../releases).
2. Open KernelSU Manager → Modules → Install from storage → pick the zip.
3. Reboot.

Or drop the module folder directly into `/data/adb/modules/cepheus-gaming-tweaks/`.

## Configuration

Edit `/data/adb/modules/cepheus-gaming-tweaks/tweak.conf` then reboot.

| Key | Default | Description |
|---|---|---|
| `GP_THERMAL` | `true` | Release thermal throttling during games |
| `GP_GPU` | `true` | Dynamic GPU floor |
| `GP_IO` | `true` | I/O scheduler |
| `GP_VM` | `true` | VM tuning |
| `GP_DYNAMIC` | `true` | `false` = apply statically (no game detection) |
| `THERMAL_DAEMONS` | `mi_thermald` | Daemon(s) to pause (space-separated) |
| `GPU_GAME_PWRLEVEL` | `4` | GPU floor during games (lower = higher clock) |
| `GPU_IDLE_PWRLEVEL` | `6` | GPU floor when idle |

## Verify

While a game is running:
```sh
su -c 'awk "{print \$3}" /proc/$(pidof mi_thermald)/stat'             # T = paused
su -c 'cat /sys/devices/system/cpu/cpufreq/policy7/scaling_max_freq'  # 2841600
```
After the game is closed, the daemon returns to `S` (normal thermal).

Log: `/data/adb/modules/cepheus-gaming-tweaks/tweak.log`

## Requirements

- Xiaomi Mi 9 (cepheus / sm8150) with KernelSU/Magisk.
- Optional: [Encore Tweaks](https://github.com/Rem01Gaming/encore) for game
  detection & CPU tuning (this module reads game state from Encore).

## Build

```sh
sh build.sh   # produces cepheus-gaming-tweaks-vX.Y.Z.zip
```

## Disclaimer

Use at your own risk. Releasing thermal throttling during games makes the device
run hotter than usual. Avoid long gaming sessions while charging.

## License

[MIT](LICENSE)
