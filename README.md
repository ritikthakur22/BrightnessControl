# Custom Minimum Brightness (BrightnessControl)

[![Magisk](https://img.shields.io/badge/Magisk-v20.4%2B-00B0FF?style=flat&logo=magisk)](https://github.com/topjohnwu/Magisk)
[![KernelSU](https://img.shields.io/badge/KernelSU-Supported-success?style=flat)](https://kernelsu.org/)
[![APatch](https://img.shields.io/badge/APatch-Supported-blueviolet?style=flat)](https://github.com/bmax121/APatch)
[![Android](https://img.shields.io/badge/Android-10--14-3DDC84?style=flat&logo=android)](https://www.android.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A lightweight, systemless Magisk / KernelSU / APatch module that intercepts and dynamically scales hardware backlight levels on Android devices. It unlocks a substantially lower minimum brightness floor (e.g., down to `20`) while preserving native, smooth UI slider travel and screen-off functionality.

---

## The Problem

On various Android devices (notably MediaTek platforms like MT6768 / MT6769 running Android 12/13/14), ROM frameworks or display drivers enforce an artificially high minimum brightness floor:
- The slider bottom is capped in hardware at values as high as **`379`** (out of a max of `2047`), leaving the screen uncomfortably bright in pitch-black rooms.
- Video players (such as MX Player, VLC) and lockscreen overlays often bypass framework settings and force the backlight to `379`.
- Direct static modifications to framework APKs or overlays often cause display desynchronization or black-screen lockups when waking the device.

---

## The Solution

This module runs a background shell daemon ([`brightness_daemon.sh`](brightness_daemon.sh)) that monitors the hardware sysfs backlight interface (`/sys/devices/platform/leds-mt65xx/leds/lcd-backlight/brightness`).

Rather than patching framework binaries, the daemon performs **real-time linear scaling**:
1. When Android or third-party apps write minimum brightness (`379`), the daemon intercepts and rescales it down to a comfortable target floor (`20`).
2. When you drag the brightness slider, the entire range between `ANDROID_MIN` and `ANDROID_MAX` is smoothly interpolated to `TARGET_MIN` and `TARGET_MAX`.
3. Screen-off detection: When the screen turns off (`CUR == 0`), the daemon remains completely transparent, preventing any black-screen wake issues.
4. Overrides third-party apps: By evaluating the sysfs node at a 100ms interval, apps attempting to force arbitrary high brightness values are immediately corrected.

### Scaling Formula

$$\text{NEW\_VAL} = \text{TARGET\_MIN} + \frac{(\text{CUR} - \text{ANDROID\_MIN}) \times (\text{TARGET\_MAX} - \text{TARGET\_MIN})}{\text{ANDROID\_MAX} - \text{ANDROID\_MIN}}$$

---

## Module Structure

```text
BrightnessControl/
├── module.prop           # Magisk module metadata and description
├── service.sh            # Boot service that launches daemon upon boot completion
├── brightness_daemon.sh  # Core polling loop and scaling calculation logic
├── action.sh             # Magisk action button script (restarts daemon on demand)
├── customize.sh          # Installation script enforcing 0755 execution permissions
├── .gitignore            # Git exclusion rules
├── LICENSE               # MIT License
└── README.md             # Documentation
```

---

## Installation

### Prerequisites
- Rooted Android device running **Magisk**, **KernelSU**, or **APatch**.
- Android 10, 11, 12, 13, or 14.

### Step 1: Package the Module
If building from source, create the flashable `.zip` archive:

```bash
cd BrightnessControl
zip -r9 CustomMinBrightness.zip ./* -x .git .gitignore "*.zip"
```

### Step 2: Flash the Zip
1. Transfer `CustomMinBrightness.zip` to your device storage.
2. Open **Magisk Manager** (or KernelSU / APatch Manager).
3. Navigate to **Modules** -> **Install from storage**.
4. Select `CustomMinBrightness.zip`.
5. Reboot your device.

---

## Configuration & Tuning

To adjust brightness boundaries or adapt the module to another device, edit [`brightness_daemon.sh`](brightness_daemon.sh):

```bash
# Sysfs node path (check /sys/class/backlight/ for your device)
NODE="/sys/devices/platform/leds-mt65xx/leds/lcd-backlight/brightness"

# Stock ROM boundaries
ANDROID_MIN=379
ANDROID_MAX=2047

# Desired custom boundaries
TARGET_MIN=20     # Lower = darker (e.g. 15, 20, 30)
TARGET_MAX=2047
```

### Finding Your Device's Backlight Node
If using a non-MediaTek device (e.g., Qualcomm Snapdragon):
```bash
su
ls -la /sys/class/backlight/
# Look for 'panel0-backlight/brightness' or similar
```
Update `NODE="..."` in `brightness_daemon.sh` with the detected path.

---

## Performance & Battery Impact

- **CPU Overhead**: Polling uses lightweight integer arithmetic in standard shell (`/system/bin/sh`). Average CPU utilization is well below **0.1%**.
- **Sleep Impact**: The daemon executes a 100ms sleep loop only when active. When the screen turns off (`CUR == 0`), no write operations are triggered.
- **Safety**: Purely systemless. If any issue arises, booting into Safe Mode automatically disables all installed Magisk modules.

---

## Uninstallation

1. Open **Magisk Manager** -> **Modules**.
2. Tap **Remove** under **Custom Minimum Brightness**.
3. Reboot. The hardware backlight reverts immediately to stock ROM behavior.

---

## License

This project is licensed under the [MIT License](LICENSE).
