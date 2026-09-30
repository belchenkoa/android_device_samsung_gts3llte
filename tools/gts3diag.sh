#!/system/bin/sh
# Full one-file diagnostics for Samsung Galaxy Tab S3 LTE / gts3llte.
# Designed for Magisk-root execution from GTS3 Diagnostics or Terminal.

MODE="${1:-all}"

if [ "$MODE" = "--save" ]; then
    OUT="${2:-/sdcard/Download/gts3diag-$(date +%Y%m%d-%H%M%S).txt}"
    NEXT_MODE="${3:-all}"
    mkdir -p "$(dirname "$OUT")" 2>/dev/null || true
    "$0" "$NEXT_MODE" >"$OUT" 2>&1
    RC=$?
    chmod 0644 "$OUT" 2>/dev/null || true
    chown media_rw:media_rw "$OUT" 2>/dev/null || chown 1023:1023 "$OUT" 2>/dev/null || true
    echo "Saved: $OUT"
    exit $RC
fi

section(){ echo; echo "===== $1 ====="; }
run(){ echo "+ $*"; "$@" 2>&1 || true; }
shrun(){ echo "+ $*"; sh -c "$*" 2>&1 || true; }

identity(){
 section "IDENTITY / BUILD"
 run date
 run id
 run uname -a
 run uptime
 run getenforce
 shrun "cat /sys/fs/selinux/enforce 2>/dev/null"
 shrun "cat /proc/cmdline"
 shrun "getprop"
 shrun "magisk -v 2>/dev/null; magisk -V 2>/dev/null; su -v 2>/dev/null"
}

selinux(){
 section "SELINUX"
 run getenforce
 shrun "mount | grep -i selinux"
 shrun "cat /sys/fs/selinux/enforce 2>/dev/null"
 shrun "cat /sys/fs/selinux/policyvers 2>/dev/null"
 shrun "cat /proc/config.gz 2>/dev/null | gzip -dc 2>/dev/null | grep -E 'CONFIG_SECURITY|CONFIG_DEFAULT_SECURITY|CONFIG_AUDIT' | head -n 240"
 shrun "ps -AZ 2>/dev/null"
 section "SELINUX AVC / AUDIT"
 shrun "dmesg 2>/dev/null | grep -Ei 'avc:|selinux|audit' | tail -n 2000"
 shrun "logcat -b all -d 2>/dev/null | grep -Ei 'avc:|selinux|audit' | tail -n 2000"
}

power(){
 section "BATTERY / POWER"
 run dumpsys battery
 shrun "dumpsys batterystats --checkin 2>/dev/null | head -n 400"
 shrun "getprop | grep -Ei 'charger|battery|power|thermal|bootreason'"
 section "POWER_SUPPLY SYSFS"
 shrun 'for d in /sys/class/power_supply/*; do [ -d "$d" ] || continue; echo "--- $d ---"; for f in type status health present online capacity voltage_now voltage_max voltage_max_design current_now current_max input_current_limit constant_charge_current_max charge_type usb_type temp technology cycle_count charge_full charge_full_design; do [ -r "$d/$f" ] && printf "%s=" "$f" && cat "$d/$f"; done; done'
 section "THERMAL"
 shrun 'for z in /sys/class/thermal/thermal_zone*; do [ -d "$z" ] || continue; printf "%s " "$z"; cat "$z/type" 2>/dev/null; cat "$z/temp" 2>/dev/null; done'
}

storage_usb(){
 section "FILESYSTEMS / STORAGE"
 run df -h
 run mount
 shrun "cat /proc/filesystems"
 shrun "cat /proc/partitions"
 shrun "blkid 2>/dev/null"
 shrun "sm list-disks 2>/dev/null; sm list-volumes all 2>/dev/null"
 shrun "dumpsys mount 2>/dev/null"
 shrun "dumpsys vold 2>/dev/null"
 shrun "ls -laZ /storage /mnt/media_rw /mnt/runtime 2>/dev/null"
 section "USB / OTG"
 shrun "dumpsys usb 2>/dev/null"
 shrun "getprop | grep -Ei 'usb|mtp|adb'"
 shrun "find /sys/bus/usb/devices -maxdepth 2 -type f \( -name idVendor -o -name idProduct -o -name product -o -name manufacturer -o -name bDeviceClass \) -print -exec cat {} \; 2>/dev/null"
 shrun "dmesg 2>/dev/null | grep -Ei 'usb|scsi|sd[a-z]|vold|sdfat|exfat|fat|ntfs' | tail -n 1200"
}

media(){
 section "CAMERA"
 shrun "dumpsys media.camera 2>/dev/null"
 section "MEDIA CODEC"
 shrun "dumpsys media.codec 2>/dev/null"
 section "MEDIA EXTRACTOR"
 shrun "dumpsys media.extractor 2>/dev/null"
 section "AUDIO"
 shrun "dumpsys audio 2>/dev/null"
 shrun "dumpsys media.audio_flinger 2>/dev/null | head -n 600"
}

hardware(){
 section "SENSORS"
 shrun "dumpsys sensorservice 2>/dev/null | head -n 800"
 section "DISPLAY"
 shrun "dumpsys display 2>/dev/null | head -n 800"
 section "SURFACEFLINGER"
 shrun "dumpsys SurfaceFlinger 2>/dev/null | head -n 800"
 section "MEMORY"
 shrun "cat /proc/meminfo"
 section "CPU"
 shrun "cat /proc/cpuinfo"
}

network_radio(){
 section "NETWORK"
 run ip addr
 run ip route
 shrun "dumpsys wifi 2>/dev/null | head -n 1200"
 shrun "getprop | grep -Ei 'wifi|wlan|dhcp|dns|net\.'"
 section "RADIO / TELEPHONY"
 shrun "getprop | grep -Ei 'gsm|ril|radio|ims|telephony'"
 shrun "dumpsys telephony.registry 2>/dev/null | head -n 1000"
 shrun "dumpsys carrier_config 2>/dev/null | head -n 600"
}

packages(){
 section "IMPORTANT PACKAGES"
 shrun "dumpsys package com.topjohnwu.magisk 2>/dev/null | grep -E 'versionName|versionCode|firstInstallTime|lastUpdateTime|pkgFlags' | head -n 80"
 shrun "dumpsys package ru.belchenkoa.gts3diag 2>/dev/null | grep -E 'versionName|versionCode|firstInstallTime|lastUpdateTime|pkgFlags' | head -n 80"
 section "SERVICES"
 shrun "service list 2>/dev/null"
}

logs(){
 section "DMESG"
 shrun "dmesg 2>/dev/null"
 section "LOGCAT ALL BUFFERS"
 shrun "logcat -b all -d -v threadtime 2>/dev/null"
 section "PSTORE / LAST KMSG"
 shrun "for f in /sys/fs/pstore/* /proc/last_kmsg; do [ -r \"$f\" ] && echo --- $f --- && cat \"$f\"; done"
}

all){
 identity
 selinux
 power
 storage_usb
 media
 hardware
 network_radio
 packages
 logs
}

case "$MODE" in
 all) all ;;
 selinux) identity; selinux ;;
 power) identity; power ;;
 storage|usb) identity; storage_usb ;;
 media|camera) identity; media ;;
 logs) identity; logs ;;
 *) echo "Usage: gts3diag [all|selinux|power|storage|usb|media|camera|logs]"; exit 2 ;;
esac
