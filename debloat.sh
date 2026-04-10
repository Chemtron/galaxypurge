#!/usr/bin/env bash
# ============================================================================
# GalaxyPurge — Samsung Galaxy Debloater & Privacy Hardener
# https://github.com/Chemtron/galaxypurge
#
# Disables spyware, telemetry, bloatware, and OTA update services on
# Samsung Galaxy devices via ADB. No root required.
#
# Tested on: Galaxy S23 Ultra (One UI 6.x / Android 14-15)
# Should work on: Galaxy S21-S25, Galaxy Z Fold/Flip, Galaxy A series
#
# Usage:
#   ./debloat.sh              # Interactive mode — choose categories
#   ./debloat.sh --all        # Disable everything
#   ./debloat.sh --spyware    # Disable only spyware-labeled packages
#   ./debloat.sh --undo       # Re-enable everything this script disabled
#   ./debloat.sh --list       # List what would be disabled (dry run)
#
# USE AT YOUR OWN RISK. The authors are not responsible for bricked
# devices, lost data, missed calls, or any other issues.
# Disabling system packages can affect phone functionality.
# A factory reset will re-enable everything.
# All changes are reversible: ./debloat.sh --undo
# ============================================================================

set -euo pipefail

VERSION="1.0.0"
BACKUP_FILE="disabled_packages_$(date +%Y%m%d_%H%M%S).txt"
UNDO_FILE="debloat_undo.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# ============================================================================
# Package lists by category
# ============================================================================

# --- OTA / System Update Services ---
OTA_UPDATES=(
    "com.sec.android.soagent|Samsung OTA Agent"
    "com.samsung.android.app.updatecenter|Samsung Update Center"
    "com.google.android.configupdater|Google Config Updater"
    "com.samsung.sdm|Samsung Device Management (security patches)"
    "com.samsung.ssu|Samsung System Updates"
    "com.sec.android.app.samsungapps|Galaxy Store (prevents silent re-enabling of OTA)"
)

# --- Google Telemetry & Ad Services [SPYWARE] ---
GOOGLE_SPYWARE=(
    "com.google.android.adservices.api|Google Ad Services — targeted ad tracking|SPYWARE"
    "com.google.mainline.adservices|Mainline Ad Services — system-level ad framework|SPYWARE"
    "com.google.mainline.telemetry|Google Mainline Telemetry — reports device data to Google|SPYWARE"
    "com.google.android.feedback|Google Feedback — sends diagnostics to Google|SPYWARE"
    "com.google.android.ondevicepersonalization.services|On-Device Personalization — profiles behavior for ads|SPYWARE"
    "com.google.android.federatedcompute|Federated Compute — on-device ML that phones home|SPYWARE"
    "com.google.android.as.oss|Private Compute Services — pipes AI data to Google|SPYWARE"
    "com.google.android.apps.turbo|Device Health Turbo — collects battery/app/device stats|SPYWARE"
    "com.google.android.modulemetadata|Module Metadata — reports module versions to Google|SPYWARE"
    "com.google.android.onetimeinitializer|One-Time Initializer — phones home on first boot"
    "com.google.android.apps.restore|Google Restore — backs up device state to Google cloud"
    "com.google.android.health.connect.backuprestore|Health Connect Backup — sends health data to Google"
    "com.google.android.printservice.recommendation|Print Recommendations — phones home to suggest printers"
    "com.android.hotwordenrollment.okgoogle|OK Google hotword — always-listening mic trigger|SPYWARE"
    "com.android.hotwordenrollment.xgoogle|Hey Google hotword — always-listening mic trigger|SPYWARE"
    "com.android.devicediagnostics|Device Diagnostics — reports hardware/software diagnostics|SPYWARE"
    "com.google.android.gms.location.history|Google Location History — tracks everywhere you go|SPYWARE"
    "com.hiya.star|Hiya Caller ID — sends phone numbers to external servers|SPYWARE"
    "com.qualcomm.location|Qualcomm Location — separate location tracking layer|SPYWARE"
)

# --- Samsung Telemetry & Analytics [SPYWARE] ---
SAMSUNG_TELEMETRY=(
    "com.samsung.android.knox.analytics.uploader|Knox Analytics — uploads usage data to Samsung|SPYWARE"
    "com.samsung.android.da.daagent|Device Analytics Agent — background behavior collection|SPYWARE"
    "com.samsung.android.rubin.app|Samsung Rubin — AI usage tracking and profiling|SPYWARE"
    "com.samsung.android.dqagent|Device Quality Agent — reports performance metrics|SPYWARE"
    "com.samsung.android.svcagent|Service Agent — phones home with device status|SPYWARE"
    "com.samsung.carrier.logcollector|Carrier Log Collector — uploads carrier network logs|SPYWARE"
    "com.sec.android.diagmonagent|Diagnostics Monitor — background diagnostics reporting|SPYWARE"
    "com.sec.android.iaft|Intelligent Anomaly Detection — monitors and reports behavior|SPYWARE"
    "com.samsung.android.ipsgeofence|IPS Geofencing — indoor positioning tracking|SPYWARE"
    "com.samsung.android.beaconmanager|Beacon Manager — BLE beacon location scanning|SPYWARE"
    "com.samsung.android.samsungpositioning|Samsung Positioning — Samsung location tracking|SPYWARE"
    "com.samsung.sait.sohservice|State of Health — reports device health metrics|SPYWARE"
    "com.sec.spp.push|Samsung Push Service — receives silent commands from Samsung|SPYWARE"
    "com.samsung.android.mcfds|MCF Data Service — Samsung cloud data sync|SPYWARE"
    "com.samsung.android.mcfserver|MCF Server — Samsung cloud framework|SPYWARE"
)

# --- Samsung Data Collection & Cloud [SPYWARE] ---
SAMSUNG_DATA_COLLECTION=(
    "com.samsung.android.bbc.bbcagent|BBC Agent — background data collection and upload|SPYWARE"
    "com.samsung.android.dsms|DSMS — device security telemetry|SPYWARE"
    "com.samsung.android.rampart|Rampart — security analytics profiling|SPYWARE"
    "com.samsung.android.scpm|Security Policy Manager — downloads policies from Samsung"
    "com.samsung.android.simagent|SIM Agent — reports SIM/carrier changes|SPYWARE"
    "com.samsung.android.gru|GRU — Samsung usage reporting|SPYWARE"
    "com.samsung.android.kmxservice|KMX Service — Knox key management"
    "com.samsung.android.visual.cloudcore|Visual Cloud Core — uploads images to Samsung cloud|SPYWARE"
    "com.samsung.android.wifi.ai|WiFi AI — collects WiFi network behavior|SPYWARE"
    "com.samsung.android.mhs.ai|Mobile Hotspot AI — collects hotspot usage patterns|SPYWARE"
    "com.samsung.android.globalpostprocmgr|Global Post-Processing Manager"
    "com.samsung.android.smartface|Smart Face — facial recognition profiling|SPYWARE"
    "com.samsung.android.smartface.overlay|Smart Face Overlay|SPYWARE"
    "com.samsung.android.mocca|Mocca — contextual awareness / behavior tracking|SPYWARE"
    "com.samsung.android.dbsc|DBSC — device behavior and state collection|SPYWARE"
    "com.samsung.android.cidmanager|CID Manager — tracks carrier/region identity changes|SPYWARE"
    "com.samsung.android.networkdiagnostic|Network Diagnostics — reports network performance|SPYWARE"
    "com.samsung.android.sdm.config|SDM Config — device management configuration"
    "com.samsung.android.location|Samsung Location — Samsung's own location service|SPYWARE"
    "com.samsung.android.ese|Samsung Embedded Secure Element"
    "com.samsung.android.easysetup|Easy Setup — phones home during setup"
    "com.samsung.android.settingshelper|Settings Helper — syncs settings to Samsung"
    "com.sec.android.app.personalization|Personalization — profiles user behavior|SPYWARE"
    "com.sec.android.app.chromecustomizations|Chrome Customizations — Samsung Chrome reporting|SPYWARE"
    "com.sec.imslogger|IMS Logger — logs VoLTE/IMS call data|SPYWARE"
    "com.samsung.android.scloud|Samsung Cloud — syncs data to Samsung servers|SPYWARE"
    "com.samsung.android.shortcutbackupservice|Shortcut Backup — backs up to Samsung cloud"
    "com.samsung.android.brightnessbackupservice|Brightness Backup — backs up to Samsung cloud"
)

# --- Galaxy AI ---
GALAXY_AI=(
    "com.samsung.android.app.interpreter|Live Translation / Interpreter"
    "com.samsung.android.app.readingglass|Reading Glass — text overlay translation"
    "com.samsung.android.photoremasterservice|Photo Remaster — AI photo enhancement"
    "com.samsung.android.callassistant|Call Assistant — AI call screening"
    "com.samsung.mediasearch|Media Search — sends images to Samsung servers|SPYWARE"
    "com.samsung.android.internal.overlay.config.default_contextual_search|Circle to Search — sends screen content for analysis|SPYWARE"
    "com.samsung.android.app.smartcapture|Smart Capture — AI screenshot analysis"
    "com.samsung.android.smartcallprovider|Smart Call Provider — external caller ID lookup"
    "com.samsung.android.service.airviewdictionary|Air View Dictionary — hover-to-translate"
    "com.samsung.android.app.sketchbook|Sketchbook — AI-assisted drawing"
    "com.samsung.android.visionintelligence|Vision Intelligence — AI scene recognition"
)

# --- Bixby ---
BIXBY=(
    "com.samsung.android.bixby.wakeup|Bixby Wake — always-listening mic trigger|SPYWARE"
    "com.samsung.android.bixbyvision.framework|Bixby Vision — sends images to Samsung|SPYWARE"
    "com.samsung.android.bixby.ondevice.enus|Bixby On-Device speech processing"
    "com.samsung.android.intellivoiceservice|Intelligent Voice Service"
    "com.samsung.android.vexfwk.service|Bixby Framework"
    "com.samsung.android.app.vex.scanner|Bixby Scanner — sends to Samsung cloud|SPYWARE"
    "com.samsung.android.bixby.agent|Bixby Agent — main assistant service"
)

# --- Verizon / Carrier ---
CARRIER=(
    "com.vzw.hss.myverizon|My Verizon — collects device and usage data|SPYWARE"
    "com.verizon.mips.services|Verizon MIPS — analytics and tracking|SPYWARE"
    "com.verizon.obdm|Verizon OBDM — remote device management|SPYWARE"
    "com.verizon.onetalk.dialer|Verizon One Talk — VoIP dialer"
    "com.samsung.vvm|Samsung Visual Voicemail"
    "com.samsung.vzwapiservice|Verizon API Service"
    "com.vzw.apnlib|Verizon APN Library (WARNING: may break mobile data/MMS)"
    "com.vzw.ecid|Verizon ECID — device identity reporting|SPYWARE"
    "com.vcast.mediamanager|Verizon Media Manager"
    "com.verizon.messaging.vzmsgs|Verizon Messages"
    "com.securityandprivacy.android.verizon.vms|Verizon Security — reports device state|SPYWARE"
)

# --- Microsoft ---
MICROSOFT=(
    "com.microsoft.appmanager|Microsoft App Manager — pushes installs/updates"
    "com.microsoft.skydrive|OneDrive — cloud storage"
)

# --- Edge Panels ---
EDGE_PANELS=(
    "com.samsung.android.app.clipboardedge|Clipboard Edge Panel"
    "com.samsung.android.app.taskedge|Task Edge Panel"
    "com.samsung.android.service.peoplestripe|People Edge Panel"
    "com.samsung.android.aircommandmanager|S Pen Air Command Manager"
    "com.samsung.android.service.aircommand|S Pen Air Command Service"
)

# --- Samsung Pay / Car Key ---
SAMSUNG_PAY=(
    "com.samsung.android.spayfw|Samsung Pay Framework"
    "com.samsung.android.carkey|Samsung Digital Car Key"
    "com.samsung.android.dkey|Samsung Digital Key"
)

# --- Unnecessary Samsung Services ---
SAMSUNG_UNNECESSARY=(
    "com.samsung.storyservice|Story Service"
    "com.samsung.videoscan|Video Scan Service"
    "com.samsung.petservice|Pet Service"
    "com.samsung.android.dynamiclock|Dynamic Lock Screen wallpapers"
    "com.samsung.android.wallpaper.live|Live Wallpapers"
    "com.samsung.android.app.dofviewer|Depth-of-Field Viewer"
    "com.samsung.android.singletake.service|Single Take camera mode"
    "com.samsung.android.visualars|Visual AR Service"
    "com.samsung.android.liveeffectservice|Live Effect Service"
    "com.samsung.android.app.routines|Bixby Routines"
    "com.samsung.android.motionphoto.app|Motion Photo playback"
    "com.samsung.mfcontents|Pre-loaded media content"
    "com.samsung.android.hdmapp|HDMI output"
    "com.sec.android.autodoodle.service|Auto Doodle on photos"
    "com.samsung.android.app.parentalcare|Samsung Parental Controls"
)

# --- Samsung Bloatware ---
SAMSUNG_BLOAT=(
    "com.samsung.android.aremojieditor|AR Emoji Editor"
    "com.samsung.android.aremoji|AR Emoji"
    "com.samsung.android.app.camera.sticker.facearavatar.preload|AR Camera Stickers"
    "com.samsung.android.stickercenter|Sticker Center"
    "com.samsung.android.game.gametools|Game Tools"
    "com.samsung.android.game.gos|Game Optimizing Service"
    "com.samsung.android.game.gamehome|Game Home"
    "com.samsung.android.forest|Samsung Forest / Digital Wellbeing"
    "com.samsung.android.lool|Samsung Members"
    "com.samsung.android.app.dressroom|AR Zone / Dressroom"
    "com.samsung.android.app.sharelive|Share Live"
    "com.samsung.android.smartsuggestions|Smart Suggestions"
    "com.samsung.android.aware.service|Aware Service"
    "com.samsung.android.mobileservice|Samsung Mobile Service"
    "com.samsung.android.app.watchmanagerstub|Watch Manager Stub"
    "com.samsung.android.smartswitchassistant|Smart Switch Assistant"
    "com.samsung.android.coldwalletservice|Cold Wallet (blockchain)"
    "com.samsung.android.mdx|Samsung DeX"
    "com.samsung.android.mdx.kit|DeX Kit"
    "com.samsung.android.calendar|Samsung Calendar (duplicate)"
    "com.samsung.android.app.reminder|Samsung Reminder"
    "com.samsung.android.app.notes.addons|Samsung Notes Add-ons"
    "com.samsung.android.appseparation|App Separation"
    "com.samsung.android.themestore|Theme Store"
    "com.sec.android.app.sbrowser|Samsung Internet Browser"
    "com.sec.android.app.popupcalculator|Popup Calculator"
    "com.sec.android.app.vepreload|Video Editor Preload"
    "com.sec.android.easyMover|Smart Switch / Easy Mover"
    "com.sec.android.mimage.avatarstickers|Avatar Stickers"
    "com.sec.app.samsungprintservice|Samsung Print Service"
    "com.sec.penup|PenUp drawing community"
    "com.mygalaxy.service|My Galaxy promotions"
    "com.facebook.orca|Facebook Messenger (pre-installed)"
)

# --- Google Bloatware ---
GOOGLE_BLOAT=(
    "com.google.android.apps.maps|Google Maps"
    "com.google.android.apps.docs|Google Docs"
    "com.google.android.apps.books|Google Play Books"
    "com.google.android.apps.magazines|Google News"
    "com.google.android.apps.bard|Google Gemini / Bard AI"
    "com.google.android.apps.googleassistant|Google Assistant"
    "com.google.android.apps.aiwallpapers|Google AI Wallpapers"
    "com.google.android.calendar|Google Calendar"
    "com.google.android.youtube|YouTube"
    "com.google.android.inputmethod.latin|Gboard keyboard"
    "com.google.android.projection.gearhead|Android Auto"
    "com.google.android.partnersetup|Google Partner Setup"
    "com.google.ar.core|Google AR Core"
    "com.google.ar.lens|Google Lens"
    "com.google.audio.hearing.visualization.accessibility.scribe|Google Sound Notifications"
    "com.google.android.apps.accessibility.voiceaccess|Voice Access"
    "com.google.chromeremotedesktop|Chrome Remote Desktop"
    "com.google.android.as|Android System Intelligence"
)

# ============================================================================
# Category metadata
# ============================================================================

declare -A CATEGORIES
CATEGORIES=(
    [1]="OTA_UPDATES|OTA / System Update Services|Prevents Samsung/Google from silently downloading and installing system updates."
    [2]="GOOGLE_SPYWARE|Google Telemetry & Ads [SPYWARE]|Disables Google ad tracking, telemetry, always-listening hotwords, and data collection."
    [3]="SAMSUNG_TELEMETRY|Samsung Telemetry & Analytics [SPYWARE]|Disables Samsung usage tracking, diagnostics, location beacons, and push services."
    [4]="SAMSUNG_DATA_COLLECTION|Samsung Data Collection & Cloud [SPYWARE]|Disables Samsung cloud uploads, facial recognition, behavior profiling, and network diagnostics."
    [5]="GALAXY_AI|Galaxy AI Features|Disables Samsung AI features (interpreter, photo remaster, Circle to Search, etc)."
    [6]="BIXBY|Bixby|Kills Samsung's AI assistant entirely."
    [7]="CARRIER|Verizon / Carrier Bloat|Disables Verizon tracking, device management, and bloatware. NOTE: Adapt for your carrier."
    [8]="MICROSOFT|Microsoft|Disables pre-installed Microsoft apps."
    [9]="EDGE_PANELS|Edge Panels|Disables Samsung edge panel UI (clipboard, tasks, contacts, S Pen)."
    [10]="SAMSUNG_PAY|Samsung Pay / Car Key|Disables Samsung Pay and digital car/door key."
    [11]="SAMSUNG_UNNECESSARY|Unnecessary Samsung Services|Disables non-essential Samsung services (live wallpapers, routines, AR, etc)."
    [12]="SAMSUNG_BLOAT|Samsung Bloatware|Disables pre-installed Samsung apps (games, AR emoji, DeX, browser, etc)."
    [13]="GOOGLE_BLOAT|Google Bloatware|Disables pre-installed Google apps (Maps, YouTube, Docs, Assistant, etc)."
)

# ============================================================================
# Functions
# ============================================================================

check_adb() {
    if ! command -v adb &>/dev/null; then
        echo -e "${RED}Error: adb not found in PATH.${RESET}"
        echo "Install Android platform-tools: https://developer.android.com/tools/releases/platform-tools"
        exit 1
    fi

    local devices
    devices=$(adb devices 2>/dev/null | grep -w "device" | grep -v "List")
    if [[ -z "$devices" ]]; then
        echo -e "${RED}Error: No device connected.${RESET}"
        echo ""
        echo "Connect via USB or wireless debugging:"
        echo "  1. Settings > Developer options > USB debugging (or Wireless debugging)"
        echo "  2. adb pair <ip>:<port> <code>    (wireless only)"
        echo "  3. adb connect <ip>:<port>        (wireless only)"
        echo "  4. Run this script again"
        exit 1
    fi

    local device_count
    device_count=$(echo "$devices" | wc -l)
    if [[ "$device_count" -gt 1 ]]; then
        echo -e "${YELLOW}Multiple devices connected. Using first device.${RESET}"
        echo "Specify device with: ADB_DEVICE=<serial> $0"
    fi

    DEVICE=${ADB_DEVICE:-$(echo "$devices" | head -1 | awk '{print $1}')}
    echo -e "${GREEN}Connected to: ${DEVICE}${RESET}"

    local model brand
    model=$(adb -s "$DEVICE" shell getprop ro.product.model 2>/dev/null || echo "unknown")
    brand=$(adb -s "$DEVICE" shell getprop ro.product.brand 2>/dev/null || echo "unknown")
    echo -e "${DIM}Device: ${brand} ${model}${RESET}"
    echo ""
}

disable_package() {
    local pkg="$1"
    local desc="$2"
    local label="${3:-}"

    # Check if package exists
    if ! adb -s "$DEVICE" shell pm list packages 2>/dev/null | grep -q "^package:${pkg}$"; then
        echo -e "  ${DIM}[-] ${pkg} — not installed, skipping${RESET}"
        return
    fi

    # Check if already disabled
    if adb -s "$DEVICE" shell pm list packages -d 2>/dev/null | grep -q "^package:${pkg}$"; then
        echo -e "  ${DIM}[x] ${pkg} — already disabled${RESET}"
        return
    fi

    # Disable
    local result
    result=$(adb -s "$DEVICE" shell "pm disable-user --user 0 ${pkg}" 2>&1)
    if echo "$result" | grep -qi "disabled\|new state"; then
        local tag=""
        [[ -n "$label" ]] && tag=" ${RED}[${label}]${RESET}"
        echo -e "  ${GREEN}[X]${RESET} ${pkg}${tag}"
        echo -e "      ${DIM}${desc}${RESET}"
        echo "$pkg" >> "$BACKUP_FILE"
    elif echo "$result" | grep -qi "protected\|SecurityException"; then
        echo -e "  ${YELLOW}[!] ${pkg} — protected, cannot disable${RESET}"
    else
        echo -e "  ${RED}[E] ${pkg} — ${result}${RESET}"
    fi
}

enable_package() {
    local pkg="$1"
    local result
    result=$(adb -s "$DEVICE" shell "pm enable ${pkg}" 2>&1)
    if echo "$result" | grep -qi "enabled\|new state"; then
        echo -e "  ${GREEN}[+]${RESET} ${pkg} — re-enabled"
    else
        echo -e "  ${DIM}[-]${RESET} ${pkg} — ${result}"
    fi
}

process_category() {
    local -n pkgs=$1
    local total=${#pkgs[@]}
    local count=0
    for entry in "${pkgs[@]}"; do
        IFS='|' read -r pkg desc label <<< "$entry"
        disable_package "$pkg" "$desc" "$label"
        ((count++))
    done
}

list_category() {
    local -n pkgs=$1
    for entry in "${pkgs[@]}"; do
        IFS='|' read -r pkg desc label <<< "$entry"
        local tag=""
        [[ -n "$label" ]] && tag=" ${RED}[${label}]${RESET}"
        echo -e "  ${pkg}${tag}"
        echo -e "    ${DIM}${desc}${RESET}"
    done
}

show_menu() {
    echo -e "${BOLD}GalaxyPurge — GalaxyPurge v${VERSION} — Samsung Galaxy Debloater & Privacy Hardener${RESET}"
    echo -e "${DIM}https://github.com/Chemtron/galaxypurge${RESET}"
    echo ""
    echo "Select categories to disable (space-separated numbers, or 'a' for all):"
    echo ""

    for i in $(seq 1 ${#CATEGORIES[@]}); do
        IFS='|' read -r varname display desc <<< "${CATEGORIES[$i]}"
        local -n arr=$varname
        local count=${#arr[@]}
        local spycount=0
        for entry in "${arr[@]}"; do
            [[ "$entry" == *"|SPYWARE" ]] && ((spycount++))
        done
        local spylabel=""
        [[ $spycount -gt 0 ]] && spylabel=" ${RED}(${spycount} spyware)${RESET}"
        printf "  ${CYAN}%2d${RESET}) %-45s %d packages%s\n" "$i" "$display" "$count" "$spylabel"
    done

    echo ""
    echo -e "  ${CYAN} s${RESET}) Spyware only — disable all packages labeled SPYWARE"
    echo -e "  ${CYAN} a${RESET}) All — disable everything listed above"
    echo -e "  ${CYAN} q${RESET}) Quit"
    echo ""
}

count_all_packages() {
    local total=0
    for i in $(seq 1 ${#CATEGORIES[@]}); do
        IFS='|' read -r varname _ _ <<< "${CATEGORIES[$i]}"
        local -n arr=$varname
        total=$((total + ${#arr[@]}))
    done
    echo $total
}

count_spyware() {
    local total=0
    for i in $(seq 1 ${#CATEGORIES[@]}); do
        IFS='|' read -r varname _ _ <<< "${CATEGORIES[$i]}"
        local -n arr=$varname
        for entry in "${arr[@]}"; do
            [[ "$entry" == *"|SPYWARE" ]] && ((total++))
        done
    done
    echo $total
}

run_spyware_only() {
    echo -e "\n${BOLD}Disabling all SPYWARE-labeled packages...${RESET}\n"
    for i in $(seq 1 ${#CATEGORIES[@]}); do
        IFS='|' read -r varname display _ <<< "${CATEGORIES[$i]}"
        local -n arr=$varname
        local has_spyware=0
        for entry in "${arr[@]}"; do
            [[ "$entry" == *"|SPYWARE" ]] && has_spyware=1 && break
        done
        if [[ $has_spyware -eq 1 ]]; then
            echo -e "${BOLD}${display}${RESET}"
            for entry in "${arr[@]}"; do
                IFS='|' read -r pkg desc label <<< "$entry"
                [[ "$label" == "SPYWARE" ]] && disable_package "$pkg" "$desc" "$label"
            done
            echo ""
        fi
    done
}

run_categories() {
    local selections=("$@")
    for sel in "${selections[@]}"; do
        if [[ -n "${CATEGORIES[$sel]+x}" ]]; then
            IFS='|' read -r varname display desc <<< "${CATEGORIES[$sel]}"
            echo -e "${BOLD}${display}${RESET}"
            echo -e "${DIM}${desc}${RESET}"
            echo ""
            process_category "$varname"
            echo ""
        else
            echo -e "${RED}Invalid selection: ${sel}${RESET}"
        fi
    done
}

run_all() {
    for i in $(seq 1 ${#CATEGORIES[@]}); do
        IFS='|' read -r varname display desc <<< "${CATEGORIES[$i]}"
        echo -e "${BOLD}${display}${RESET}"
        echo -e "${DIM}${desc}${RESET}"
        echo ""
        process_category "$varname"
        echo ""
    done
}

run_undo() {
    echo -e "${BOLD}Re-enabling packages...${RESET}"
    echo ""

    # Look for backup files
    local backups
    backups=$(ls disabled_packages_*.txt 2>/dev/null || true)
    if [[ -z "$backups" ]]; then
        echo -e "${YELLOW}No backup files found. Re-enabling ALL known packages from this script.${RESET}"
        echo ""
        for i in $(seq 1 ${#CATEGORIES[@]}); do
            IFS='|' read -r varname display _ <<< "${CATEGORIES[$i]}"
            local -n arr=$varname
            echo -e "${BOLD}${display}${RESET}"
            for entry in "${arr[@]}"; do
                IFS='|' read -r pkg _ _ <<< "$entry"
                enable_package "$pkg"
            done
            echo ""
        done
    else
        echo "Found backup files:"
        local i=1
        for f in $backups; do
            local count
            count=$(wc -l < "$f")
            echo "  $i) $f ($count packages)"
            ((i++))
        done
        echo ""
        echo -n "Enter number to restore (or 'a' for all backups): "
        read -r choice

        if [[ "$choice" == "a" ]]; then
            for f in $backups; do
                echo -e "\n${BOLD}Restoring from ${f}...${RESET}"
                while IFS= read -r pkg; do
                    [[ -n "$pkg" ]] && enable_package "$pkg"
                done < "$f"
            done
        else
            local target
            target=$(echo "$backups" | sed -n "${choice}p")
            if [[ -n "$target" ]]; then
                echo -e "\n${BOLD}Restoring from ${target}...${RESET}"
                while IFS= read -r pkg; do
                    [[ -n "$pkg" ]] && enable_package "$pkg"
                done < "$target"
            else
                echo -e "${RED}Invalid choice.${RESET}"
            fi
        fi
    fi

    echo ""
    echo -e "${BOLD}Also resetting OTA system settings...${RESET}"
    adb -s "$DEVICE" shell settings put global ota_disable_automatic_update 0 2>/dev/null
    adb -s "$DEVICE" shell settings put global galaxy_system_update_block -1 2>/dev/null
    echo "  ota_disable_automatic_update = 0"
    echo "  galaxy_system_update_block = -1"
    echo ""
    echo -e "${GREEN}Done. Reboot your phone for changes to take full effect.${RESET}"
}

run_list() {
    echo -e "${BOLD}Packages that would be disabled:${RESET}\n"
    local total=0
    local spyware=0
    for i in $(seq 1 ${#CATEGORIES[@]}); do
        IFS='|' read -r varname display _ <<< "${CATEGORIES[$i]}"
        local -n arr=$varname
        echo -e "${BOLD}${display}${RESET} (${#arr[@]} packages)"
        list_category "$varname"
        total=$((total + ${#arr[@]}))
        for entry in "${arr[@]}"; do
            [[ "$entry" == *"|SPYWARE" ]] && ((spyware++))
        done
        echo ""
    done
    echo -e "${BOLD}Total: ${total} packages (${spyware} labeled SPYWARE)${RESET}"
}

lock_ota_settings() {
    echo -e "${BOLD}Locking OTA system settings...${RESET}"
    adb -s "$DEVICE" shell settings put global ota_disable_automatic_update 1 2>/dev/null
    adb -s "$DEVICE" shell settings put global galaxy_system_update_block 1 2>/dev/null
    adb -s "$DEVICE" shell settings put global galaxy_system_update -1 2>/dev/null
    adb -s "$DEVICE" shell settings put global auto_omc_update 0 2>/dev/null
    echo "  ota_disable_automatic_update = 1"
    echo "  galaxy_system_update_block = 1"
    echo "  galaxy_system_update = -1"
    echo "  auto_omc_update = 0"
    echo ""
}

# ============================================================================
# Main
# ============================================================================

main() {
    case "${1:-}" in
        --all)
            check_adb
            echo -e "${BOLD}GalaxyPurge v${VERSION} — Full Disable${RESET}\n"
            run_all
            lock_ota_settings
            echo -e "${GREEN}Done. ${BACKUP_FILE} created with list of disabled packages.${RESET}"
            echo -e "${YELLOW}Reboot your phone for changes to take full effect.${RESET}"
            ;;
        --spyware)
            check_adb
            echo -e "${BOLD}GalaxyPurge v${VERSION} — Spyware Only${RESET}\n"
            run_spyware_only
            lock_ota_settings
            echo -e "${GREEN}Done. $(count_spyware) spyware packages targeted.${RESET}"
            ;;
        --undo)
            check_adb
            run_undo
            ;;
        --list)
            run_list
            ;;
        --help|-h)
            echo "GalaxyPurge — GalaxyPurge v${VERSION} — Samsung Galaxy Debloater & Privacy Hardener"
            echo ""
            echo "Usage:"
            echo "  $0              Interactive mode — choose categories"
            echo "  $0 --all        Disable everything"
            echo "  $0 --spyware    Disable only SPYWARE-labeled packages"
            echo "  $0 --undo       Re-enable disabled packages"
            echo "  $0 --list       Dry run — list what would be disabled"
            echo "  $0 --help       Show this help"
            echo ""
            echo "Requires: adb (Android platform-tools)"
            echo "No root required. Works via USB or wireless debugging."
            ;;
        *)
            check_adb
            show_menu
            echo -n "Selection: "
            read -r input

            case "$input" in
                q|Q) echo "Bye."; exit 0 ;;
                a|A)
                    echo ""
                    total=$(count_all_packages)
                    echo -e "${YELLOW}This will disable ${total} packages. Continue? [y/N]${RESET} "
                    read -r confirm
                    [[ "$confirm" != "y" && "$confirm" != "Y" ]] && exit 0
                    echo ""
                    run_all
                    lock_ota_settings
                    ;;
                s|S)
                    echo ""
                    run_spyware_only
                    lock_ota_settings
                    ;;
                *)
                    echo ""
                    IFS=' ' read -ra selections <<< "$input"
                    run_categories "${selections[@]}"
                    # Lock OTA settings if category 1 was selected
                    for s in "${selections[@]}"; do
                        [[ "$s" == "1" ]] && lock_ota_settings && break
                    done
                    ;;
            esac

            echo -e "${GREEN}Done. Disabled packages saved to ${BACKUP_FILE}${RESET}"
            echo -e "${YELLOW}Reboot your phone for changes to take full effect.${RESET}"
            ;;
    esac
}

main "$@"
