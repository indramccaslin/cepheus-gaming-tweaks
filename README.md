# Cepheus Gaming Tweaks

Modul **KernelSU / Magisk** untuk kelancaran FPS game di **Xiaomi Mi 9 (cepheus, sm8150)**.

Menggabungkan pelepas *throttle* thermal + tweak GPU/I/O/VM dalam satu module, dan
**semua tweak berat hanya aktif saat game di foreground**. Di luar game, sistem
berjalan normal.

## Fitur

- **Lepas throttle thermal saat game** — `mi_thermald` (daemon thermal userspace
  Xiaomi) membatasi CPU big/prime ke ~1.28–1.49 GHz begitu suhu kulit
  (`quiet_therm`) 44–48 °C. Module ini mem-*pause* daemon tersebut saat game,
  sehingga CPU kembali bebas (2.42 / 2.84 GHz) dan FPS tidak drop saat banyak
  musuh.
- **GPU floor dinamis** — floor GPU naik saat game (frame pacing stabil).
- **I/O `deadline`** + **VM tuning** (vfs_cache_pressure, dirty_writeback).
- **Aman bareng Encore Tweaks** — CPU governor/cpufreq/schedtune tetap diurus
  Encore; module ini tidak menyentuhnya. Status game dibaca read-only dari Encore.

## Cara kerja pelepas thermal

1. Saat game aktif:
   - `kill -STOP` daemon thermal (`THERMAL_DAEMONS`, default `mi_thermald`).
   - Reset `cooling_device` (`thermal-cpufreq-*`, `thermal-devfreq-*`) ke 0.
   - Buka clamp `scaling_max_freq` CPU ke `cpuinfo_max_freq`.
2. Saat game ditutup: `kill -CONT` → thermal normal lagi.
3. Guard: bila daemon di-restart sistem saat game, otomatis di-*pause* ulang.

> Proteksi **kernel** tetap berjalan (lmh-dcvs ±85 °C, pop-mem/cpu-step 95–110 °C,
> thermal HAL). Jadi panas ekstrem tetap ditangani kernel; hanya limit "panas
> wajar" (44–48 °C) dari userspace yang dilepas saat game.

## Instalasi

KernelSU Next / KernelSU Manager:
1. Unduh `cepheus-gaming-tweaks-vX.Y.Z.zip` dari [Releases](../../releases).
2. Buka KernelSU Manager → Modules → Install from storage → pilih zip.
3. Reboot.

Atau pasang folder module langsung ke `/data/adb/modules/cepheus-gaming-tweaks/`.

## Konfigurasi

Edit `/data/adb/modules/cepheus-gaming-tweaks/tweak.conf` lalu reboot.

| Key | Default | Keterangan |
|---|---|---|
| `GP_THERMAL` | `true` | Lepas throttle thermal saat game |
| `GP_GPU` | `true` | GPU floor dinamis |
| `GP_IO` | `true` | I/O scheduler |
| `GP_VM` | `true` | VM tuning |
| `GP_DYNAMIC` | `true` | `false` = terapkan statis (tanpa deteksi game) |
| `THERMAL_DAEMONS` | `mi_thermald` | Daemon yang di-pause (pisah spasi) |
| `GPU_GAME_PWRLEVEL` | `4` | Floor GPU saat game (makin kecil = makin tinggi) |
| `GPU_IDLE_PWRLEVEL` | `6` | Floor GPU saat idle |

## Verifikasi

Saat game berjalan:
```sh
su -c 'awk "{print \$3}" /proc/$(pidof mi_thermald)/stat'             # T = paused
su -c 'cat /sys/devices/system/cpu/cpufreq/policy7/scaling_max_freq'  # 2841600
```
Saat game ditutup, daemon kembali `S` (thermal normal).

Log: `/data/adb/modules/cepheus-gaming-tweaks/tweak.log`

## Requirements

- Xiaomi Mi 9 (cepheus / sm8150), Android dengan KernelSU/Magisk.
- Opsional: [Encore Tweaks](https://github.com/Rem01Gaming/encore) untuk deteksi game
  & tuning CPU (module ini membaca status game dari Encore).

## Build

```sh
sh build.sh   # menghasilkan cepheus-gaming-tweaks-vX.Y.Z.zip
```

## Disclaimer

Gunakan dengan risiko sendiri. Pelepas thermal saat game membuat perangkat lebih
panas dari biasanya. Hindari bermain sambil mengisi daya dalam waktu lama.

## Lisensi

[MIT](LICENSE)
