# BrightnessControl

A systemless Magisk module that intercepts and scales hardware brightness on Android devices, allowing for a custom minimum brightness limit while maintaining a smooth native slider experience.

## The Problem
On certain Android devices (especially MediaTek devices on Android 13), the ROM enforces a hardcoded minimum brightness (e.g., `379`), which can still be uncomfortably bright in dark environments.
Third-party apps (like MX Player) and the lock screen may also bypass user settings and force their own brightness limits. Direct modifications to system files often result in screen-off issues or fight with the Android framework's `DisplayPowerController`.

## The Solution
This module solves the problem by running a lightweight bash daemon (`brightness_daemon.sh`) at boot. The daemon continuously monitors the hardware's sysfs backlight node (e.g., `/sys/devices/platform/leds-mt65xx/leds/lcd-backlight/brightness`). 

Instead of fighting the Android framework, the daemon acts as a real-time translator:
- When Android attempts to set the brightness to its hardcoded minimum (e.g., `379`), the daemon intercepts it and scales it down to a much dimmer custom limit (e.g., `20`).
- It mathematically scales the entire slider range. Moving the slider smoothly adjusts the hardware brightness from `20` all the way up to the hardware maximum (e.g., `2047`).
- Because it actively overrides values 10 times a second, it natively defeats apps like MX Player that try to force the brightness back up to `379`.
- It includes a safety check for `0` (screen off) to prevent black-screen bricking issues.

## Module Structure

- **`service.sh`**: Executed by Magisk late in the boot process. It launches the daemon in the background.
- **`brightness_daemon.sh`**: The core script. It contains the scaling mathematics and the loop that polls the sysfs node.
- **`action.sh`**: Executed if you tap the action button in the Magisk app. Kills and restarts the daemon.
- **`customize.sh`**: The installation script that sets the proper execution permissions (0755) during Magisk flashing.
- **`module.prop`**: Contains the module metadata (ID, version, author).

## How It's Built & Packaged
1. **Write the Scripts:** The logic is written purely in standard shell scripting to ensure maximum compatibility.
2. **Zip the Files:** The files are packaged into a standard `.zip` file suitable for Magisk. 
   ```bash
   zip -r CustomMinBrightness.zip .
   ```
3. **Installation:** Flash the resulting `.zip` file in the Magisk Manager and reboot.

## Safety & Anti-Bricking
- **Systemless:** The module does not touch `/system` or `/vendor` partitions. If a bootloop occurs, boot into Safe Mode to automatically disable all Magisk modules.
- **Screen-Off Check:** If the screen turns off (`value == 0`), the daemon ignores it, guaranteeing that the screen will wake up normally when the power button is pressed.
- **Bounds Checking:** It forces a hard minimum, ensuring the hardware value can never drop to `1` or `0` while the screen is meant to be on.
