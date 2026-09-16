#!/system/bin/sh

# Non-destructive diagnostics for Samsung Galaxy Tab S3 LTE (SM-T825 / gts3llte).
# Works from LineageOS Terminal, adb shell, and adb root. Privileged sections
# automatically include more data when uid=0.

MODE="${1:-all}"

if [ "$MODE" = "--save" ]; then
    OUT="${2:-/sdcard/Download/gts3diag-$(date +%Y%m%d-%H%M%S).txt}"
    NEXT_MODE="${3:-all}"
    "$0" "$NEXT_MODE" 2>&1 | tee "$OUT"
    echo "Saved: $OUT"
    exit 0
fi

section() {
    echo
    echo "===== $1 ====="
}

cmd() {
    echo "+ $*"
    "$@" 2>&1 || true
}

shcmd() {
    echo "+ $*"
    sh -c "$*" 2>&1 || true
}

is_root() {
    [ "$(id -u 2>/dev/null)" = "0" ]
}

basic() {
    section "IDENTITY"
    cmd id
    cmd uname -a
    cmd getenforce
    cmd uptime
    shcmd "getprop ro.product.device; getprop ro.product.model; getprop ro.build.version.release; getprop ro.lineage.version; getprop ro.build.fingerprint; getprop sys.boot_completed"

    section "MEMORY"
    shcmd "cat /proc/meminfo | head -n 20"

    section "CPU"
    shcmd "cat /proc/cpuinfo | head -n 80"
}

network() {
    section "NETWORK"
    cmd ip addr
    cmd ip route
    shcmd "getprop | grep -Ei 'wifi|wlan|dhcp|dns' | head -n 160"
    shcmd "dumpsys wifi | grep -Ei 'Wi-Fi is|mWifiInfo|SSID|BSSID|MAC|NetworkInfo|Supplicant|SoftAp|hostapd' | head -n 220"
}

radio() {
    section "RADIO / LTE / IMS"
    shcmd "getprop | grep -Ei 'gsm|ril|radio|ims|telephony' | head -n 220"
    shcmd "dumpsys telephony.registry | head -n 260"
    shcmd "dumpsys carrier_config | head -n 160"
}

power() {
    section "BATTERY"
    cmd dumpsys battery
    shcmd "getprop | grep -Ei 'bootreason|charger|battery|power' | head -n 160"

    section "POWER SUPPLY SYSFS"
    shcmd 'for d in /sys/class/power_supply/*; do [ -d "$d" ] || continue; echo "--- $d ---"; for f in type status capacity health online voltage_now current_now temp charge_type usb_type; do [ -r "$d/$f" ] && printf "%s=" "$f" && cat "$d/$f"; done; done'
}

storage() {
    section "STORAGE"
    cmd df -h
    shcmd "mount | grep -E '/data|/storage|/mnt/media_rw|sdcard'"
    shcmd "ls -la /storage 2>/dev/null; ls -la /mnt/media_rw 2>/dev/null"
    shcmd "getprop | grep -Ei 'vold|storage|sdcard' | head -n 160"
}

sensors() {
    section "SENSORS"
    shcmd "dumpsys sensorservice | head -n 260"

    section "FINGERPRINT"
    shcmd "dumpsys fingerprint | head -n 180"
}

audio() {
    section "AUDIO"
    shcmd "dumpsys audio | head -n 260"
    shcmd "dumpsys media.audio_flinger | head -n 180"
}

graphics() {
    section "DISPLAY / GRAPHICS"
    shcmd "dumpsys display | head -n 220"
    shcmd "dumpsys SurfaceFlinger | head -n 180"
}

usb() {
    section "USB"
    shcmd "getprop | grep -Ei 'usb|mtp|adb' | head -n 180"
    shcmd "ls -la /sys/class/android_usb 2>/dev/null; ls -la /sys/class/udc 2>/dev/null"
}

logs() {
    section "LOGCAT TAIL"
    shcmd "logcat -d -t 300"

    if is_root; then
        section "DMESG TAIL (ROOT)"
        shcmd "dmesg | tail -n 300"
    else
        section "ROOT-ONLY LOGS"
        echo "Not root. For kernel diagnostics use: adb root && adb shell gts3diag logs"
    fi
}

root_extra() {
    section "ROOT STATUS"
    if is_root; then
        echo "uid=0: privileged checks enabled"
        shcmd "cat /proc/cmdline"
        shcmd "cat /sys/fs/selinux/enforce 2>/dev/null"
        shcmd "find /sys/class/power_supply -maxdepth 2 -type f 2>/dev/null | head -n 120"
    else
        echo "uid=$(id -u 2>/dev/null): privileged checks skipped"
        echo "Use adb root, then adb shell gts3diag all for full diagnostics."
    fi
}

case "$MODE" in
    basic) basic ;;
    network) network ;;
    radio) radio ;;
    power) power ;;
    storage) storage ;;
    sensors) sensors ;;
    audio) audio ;;
    graphics) graphics ;;
    usb) usb ;;
    logs) logs ;;
    all)
        basic
        network
        radio
        power
        storage
        sensors
        audio
        graphics
        usb
        root_extra
        ;;
    *)
        echo "Usage: gts3diag [all|basic|network|radio|power|storage|sensors|audio|graphics|usb|logs]"
        echo "       gts3diag --save [output-file] [mode]"
        exit 2
        ;;
esac
