<h1 align="center">iPhone X iOS 11.1 Tethered Downgrade & Boot Toolkit</h1>

<p align="center">
  <a href="https://github.com/jasicki/iphonex_ios11-downgrade" target="_blank">
    <img src="https://img.shields.io/badge/Device-iPhone%20X%20(A11)-black.svg?style=flat&logo=apple" alt="iPhone X">
  </a>
  <a href="https://github.com/jasicki/iphonex_ios11-downgrade" target="_blank">
    <img src="https://img.shields.io/badge/iOS-11.1%20(15B93)-blue.svg?style=flat" alt="iOS 11.1">
  </a>
  <a href="https://github.com/jasicki/iphonex_ios11-downgrade" target="_blank">
    <img src="https://img.shields.io/badge/Exploit-checkm8-red.svg?style=flat" alt="checkm8">
  </a>
  <a href="https://github.com/jasicki/iphonex_ios11-downgrade/blob/main/LICENSE" target="_blank">
    <img src="https://img.shields.io/badge/License-MIT-green.svg?style=flat" alt="License">
  </a>
</p>

<p align="center">
  A clean, automated toolkit to tethered boot and fix dual-booted <b>pure iOS 11.1 (Build 15B93)</b> on <b>iPhone X (<code>iPhone10,6</code> / <code>d221ap</code>)</b> directly to SpringBoard Home Screen without Apple logo hangs or Setup.app deadlocks.
</p>

---

## ?? Overview

Downgrading the iPhone X back to its original launch software?**iOS 11.1**?via tethered dual-booting has historically been plagued by two critical issues:
1. **The Blank White Screen / Setup Freeze:** Swiping up on the initial "Hello" screen hangs indefinitely due to missing or mismatched activation state and `lockdownd` communication deadlocks.
2. **The Apple Logo Freeze:** Deleting or disabling `Setup.app` causes SpringBoard's startup transition factory (`SBStartupTransitionToSetup`) to never call its completion block. As a result, the boot overlay (`BKSDisplayRenderOverlay`) is never dismissed, leaving the phone stuck on the Apple logo forever despite the OS booting successfully in the background.

This repository provides the definitive fix: **a reverse-engineered ARM64 binary patch for `SpringBoard`**, pre-configured system preferences, proper lockdown activation structures, and a streamlined one-click tethered boot script.

---

## ? Features

- **Direct Home Screen Boot:** Bypasses Setup entirely by forcing `SpringBoard` startup transition directly to `Destination 1` (`SBStartupTransitionToHome`), immediately dismissing `BKSDisplayRenderOverlay` (the Apple logo).
- **Pure iOS 11.1 Experience:** Retains all stock iOS 11.1 UI elements, original wallpaper, system icons, animations, and bundled 32-bit/64-bit app support.
- **Lockdown & Usbmuxd Fix:** Configures pristine `data_ark.plist` records stamped with Build `15B93` to prevent `ERROR: Could not connect to lockdownd: Missing value (-12)`.
- **Standalone & Portable:** Self-contained `boot.sh` script with dedicated `gaster` and `irecovery` binaries and pre-extracted patched bootchain (`iBSS`, `iBEC`, `devicetree`, `kernelcache`).
- **Disaster Recovery Script:** Includes `restore_patches_via_ramdisk.sh` to reinstall all required binaries and configurations via SSH Ramdisk at any time without wiping your device.

---

## ?? Supported Devices & Firmware

| Parameter | Specification |
| :--- | :--- |
| **Device** | iPhone X (Global / GSM: `iPhone10,6`, Board: `d221ap`) |
| **Processor** | Apple A11 Bionic (`t8015` / `0x8015`) |
| **Target iOS** | iOS 11.1 (Build `15B93`) |
| **Base iOS** | iOS 16.7.x (installed on main APFS partition) |
| **Host OS** | macOS (High Sierra 10.13.6 or newer) / Linux (x86_64) |

> [!NOTE]
> Other A11 models (e.g. `iPhone10,3`, iPhone 8, iPhone 8 Plus) can be supported by generating their corresponding bootchain files and patching the respective `SpringBoard` binary offsets.

---

## ?? Technical Deep Dive: The SpringBoard Patch

In iOS 11, `SpringBoard` determines the destination of its startup transition via `[SBStartupTransitionFactory transitionForContext:outDestination:]`:
- `Destination 0`: `SBStartupTransitionToLockOut` (Lock Screen)
- `Destination 1`: `SBStartupTransitionToHome` (Home Screen / SpringBoard icon grid)
- `Destination 2`: `SBStartupTransitionToApp`
- `Destination 3`: `SBStartupTransitionToSetup` (`Setup.app` / Buddy)

When `requiresSetup` evaluates to `1`, SpringBoard chooses `Destination 3`. Inside `SBStartupTransitionToSetup`, SpringBoard calls:
```objc
[self _activateSetupWithCompletion:underLock:fromSnapshot:];
```
If `Setup.app` is deleted or fails to launch, the completion block is **never invoked**. Because the completion handler is responsible for telling `BKSDisplayRenderOverlay` to tear down the boot image, the screen remains permanently stuck on the Apple logo.

### The Fix:
Three methods in `SpringBoard` were reverse-engineered and patched directly at their ARM64 entry points to unconditionally return `NO` (`mov w0, #0; ret` -> `00 00 80 52 c0 03 5f d6`):
1. `-[SBInitialRestartState requiresSetup]` (Offset `0x387264`): Forces `requiresSetup` to evaluate to `0`, making SpringBoard skip Destination 3 and choose Destination 1.
2. `-[SBSetupManager isInSetupMode]` (Offset `0x2372c4`): Ensures no subsystem believes the device is in setup mode.
3. `-[SBSetupManager updateInSetupMode]` (Offset `0x2372f4`): Prevents buddy launch triggers from reacting to activation state changes.

Once patched and re-signed with `ldid -s`, SpringBoard transitions directly to Home Screen upon kernel boot and immediately dismisses the Apple logo overlay!

---

## ??? Prerequisites

1. **Hardware:**
   - iPhone X (`iPhone10,6`)
   - **USB-A to Lightning Cable** *(USB-C to Lightning cables often fail to negotiate checkm8 DFU exploit stages on A11)*.
2. **Software (Host):**
   - macOS or Linux
   - Homebrew / package manager with `libimobiledevice` and `sshpass` installed:
     ```bash
     brew install libimobiledevice sshpass
     ```

---

## ?? Step-by-Step Usage

### 1. Clone the Repository
```bash
git clone https://github.com/jasicki/iphonex_ios11-downgrade.git
cd iphonex_ios11-downgrade
```

### 2. Enter DFU Mode on iPhone X
To enter DFU mode from a powered-on or recovery state:
1. Quick-press **Volume Up**.
2. Quick-press **Volume Down**.
3. Press and hold the **Side Button (Power)** until the display turns completely black.
4. Immediately hold both **Side Button** and **Volume Down** together for exactly **5 seconds**.
5. Release the **Side Button**, but continue holding **Volume Down** for another **5 seconds**.
6. The screen must stay entirely black.

### 3. Boot iOS 11.1
Run the tethered boot script:
```bash
./boot.sh
```
The script will automatically:
- Detect the iPhone X in DFU mode.
- Execute `checkm8` via `gaster pwn` and reset the USB bus.
- Upload `iBSS.img4` and `iBEC.img4`.
- Execute `devicetree.img4` and patched `kernelcache.img4`.
- Issue `bootx` to hand over execution to the iOS 11.1 XNU kernel.

The device will boot within 15?20 seconds straight into the iOS 11.1 Home Screen!

---

## ?? Disaster Recovery: Re-applying Patches via SSH Ramdisk

If you ever reset the device's Data partition or need to re-apply the patches manually:

1. Boot into an SSH Ramdisk using [SSHRD_Script](https://github.com/jasicki/SSHRD_Script):
   ```bash
   ./sshrd.sh boot
   ```
2. Run the automated patch restoration script:
   ```bash
   ./scripts/restore_patches_via_ramdisk.sh
   ```
   This will mount `/dev/disk1s8` (System) and `/dev/disk1s9` (Data), deploy the patched `SpringBoard`, write the clean preferences, stamp `data_ark.plist`, safely unmount, and reboot.
3. Put the phone into DFU mode and run `./boot.sh`.

---

## ?? Known Limitations

- **Tethered Boot:** Since this is a checkm8 tethered downgrade without SHSH blobs, you must run `./boot.sh` from your computer whenever the iPhone reboots or runs out of battery.
- **Passcode & Face ID:** Biometrics (Face ID) and device passcode are disabled due to SEP (Secure Enclave Processor) firmware incompatibilities between iOS 16 and iOS 11.
- **Cellular & Baseband:** Mobile data/calling will not function across major baseband generational gaps; Wi-Fi and Bluetooth work completely.

---

## ?? Credits & Acknowledgements

- **[axi0mX](https://github.com/axi0mX)** for the groundbreaking `checkm8` bootrom exploit.
- **[verygenericname](https://github.com/verygenericname)** for `SSHRD_Script`.
- **[LukeZGD](https://github.com/LukeZGD)** for `Legacy-iOS-Kit` and invaluable tooling documentation.
- **[0x776bed](https://github.com/0x776bed)** for `gaster`.
- **[Nathan](https://github.com/nathan)** & **Ralph0045** for dual-boot and ramdisk research.
- **[1achu (jasicki)](https://github.com/jasicki)** for authoring this toolkit, reverse-engineering the SpringBoard transition, and developing the patches.
