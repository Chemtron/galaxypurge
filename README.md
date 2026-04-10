<p align="center">
  <img src="assets/banner.svg" alt="GalaxyPurge" width="700">
</p>

<p align="center">
  <strong>Samsung Galaxy Debloater & Privacy Hardener</strong><br>
  <em>59 spyware packages. 173 total. One command.</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/root-not%20required-green" alt="No Root">
  <img src="https://img.shields.io/badge/warranty-safe-green" alt="Warranty Safe">
  <img src="https://img.shields.io/badge/packages-173-blue" alt="173 Packages">
  <img src="https://img.shields.io/badge/spyware-59-red" alt="59 Spyware">
  <img src="https://img.shields.io/badge/license-MIT-lightgrey" alt="MIT License">
</p>

---

> **USE AT YOUR OWN RISK.** This script disables system packages on your phone. While it does not uninstall anything and all changes are reversible, disabling the wrong package can affect phone functionality. The authors are not responsible for bricked devices, lost data, missed calls, or any other issues. Always review what you're disabling and keep the backup file.

Disable spyware, telemetry, bloatware, and forced OTA updates on Samsung Galaxy devices via ADB. **No root required.**

## What This Does

Samsung Galaxy phones ship with **59+ packages that silently collect and transmit your data** to Samsung, Google, Qualcomm, and your carrier — including location tracking, usage profiling, ad targeting, always-listening hotwords, and facial recognition.

This script disables them all with one command.

| Category | Packages | Spyware |
|---|---|---|
| OTA / System Updates | 6 | - |
| Google Telemetry & Ads | 19 | 15 |
| Samsung Telemetry & Analytics | 15 | 15 |
| Samsung Data Collection & Cloud | 28 | 21 |
| Galaxy AI | 11 | 2 |
| Bixby | 7 | 3 |
| Verizon / Carrier | 11 | 5 |
| Microsoft | 2 | - |
| Edge Panels | 5 | - |
| Samsung Pay / Car Key | 3 | - |
| Unnecessary Services | 15 | - |
| Samsung Bloatware | 33 | - |
| Google Bloatware | 18 | - |
| **Total** | **173** | **59** |

## Requirements

- **ADB** (Android Debug Bridge) — [download platform-tools](https://developer.android.com/tools/releases/platform-tools)
- **USB Debugging** or **Wireless Debugging** enabled on your phone
  - Settings > Developer options > USB debugging (or Wireless debugging)
- Works on **Linux, macOS, and Windows** (Git Bash / WSL)

## Quick Start

```bash
# Clone
git clone https://github.com/Chemtron/galaxypurge.git
cd galaxypurge

# Connect your phone via USB or wireless debugging
adb devices

# Interactive mode — choose what to disable
./debloat.sh

# Or just kill all spyware
./debloat.sh --spyware

# Or disable everything
./debloat.sh --all
```

## Usage

```
./debloat.sh              # Interactive — pick categories from a menu
./debloat.sh --spyware    # Disable only SPYWARE-labeled packages (59 packages)
./debloat.sh --all        # Disable everything (173 packages)
./debloat.sh --list       # Dry run — see what would be disabled
./debloat.sh --undo       # Re-enable everything
./debloat.sh --help       # Show help
```

## How It Works

Uses `adb shell pm disable-user --user 0 <package>` to disable packages at the user level. This:

- Does **not** uninstall anything — packages can be re-enabled at any time
- Does **not** require root
- Does **not** trip Knox or void warranty
- Survives reboots
- Does **not** survive factory reset (re-run the script after reset)

## Categories

### Spyware (59 packages)

Packages labeled **SPYWARE** silently collect, profile, or transmit your data to external servers:

- **Google**: Ad tracking, telemetry, federated compute (on-device ML that phones home), always-listening "OK/Hey Google" hotwords, location history, device diagnostics
- **Samsung**: Knox analytics, device analytics, usage profiling (Rubin), carrier log collection, diagnostics, indoor positioning, beacon scanning, facial recognition, cloud image processing, WiFi/hotspot behavior tracking, push service (receives silent commands)
- **Qualcomm**: Separate location tracking layer independent of Google/Samsung
- **Hiya**: Pre-installed caller ID that sends every phone number you receive to external servers
- **Verizon**: MIPS analytics, OBDM remote device management, ECID device identity reporting

### OTA Updates

Blocks **5 separate update pathways**:
1. `com.sec.android.soagent` — Samsung OTA Agent
2. `com.samsung.android.app.updatecenter` — Samsung Update Center
3. `com.google.android.configupdater` — Google Config Updater
4. `com.samsung.sdm` — Samsung Device Management (security patches — discovered operating independently)
5. `com.samsung.ssu` — Samsung System Updates

Also disables Galaxy Store to prevent it from silently updating OTA packages, and locks system settings:
- `ota_disable_automatic_update = 1`
- `galaxy_system_update_block = 1`

### Everything Else

Bixby, Galaxy AI (Circle to Search, Photo Remaster, Call Assistant, etc.), Samsung Pay, edge panels, AR emoji, games, DeX, carrier bloat, and more. See `--list` for the full inventory.

## Undo

```bash
# Re-enable from backup file (created automatically when you run the script)
./debloat.sh --undo

# Or manually re-enable a specific package
adb shell pm enable <package.name>
```

## Tested On

- Samsung Galaxy S23 Ultra (SM-S918U, One UI 6.x, Android 14/15)

Should work on any Samsung Galaxy device (S21-S25, Z Fold/Flip, A series). Some packages may not exist on all models — the script skips missing packages automatically.

## Carrier Note

The Verizon/carrier category targets Verizon-specific packages. If you're on a different carrier:
- **T-Mobile**: Look for `com.tmobile.*`, `com.sprint.*`
- **AT&T**: Look for `com.att.*`
- **Unlocked**: You may not have carrier bloat at all

Use `adb shell pm list packages | grep -i <carrier>` to find yours.

## Disclaimer

**USE AT YOUR OWN RISK.** This script is provided as-is with no warranty. Disabling system packages may cause unexpected behavior. All changes are reversible via `--undo` or `adb shell pm enable <package>`, but you are solely responsible for any consequences of running this script on your device.

## FAQ

**Will this break my phone?**
No. Core functionality (calls, texts, camera, WiFi, Bluetooth, apps) is untouched. If something stops working, re-enable it: `adb shell pm enable <package>`.

**Will this void my warranty?**
No. Disabling packages via `pm disable-user` does not trip Knox or modify the system partition.

**Does this survive a reboot?**
Yes. Does NOT survive a factory reset.

**Can I still use Google Play Store?**
Yes. Play Store and Play Services are not touched.

**What about Find My Phone?**
Samsung Find My Mobile (`com.samsung.android.fmm`) is a protected package and cannot be disabled — it stays active.

## License

MIT

## Credits

Built by reverse-engineering every Samsung, Google, Qualcomm, and Verizon package on a Galaxy S23 Ultra to determine which ones phone home.
