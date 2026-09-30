package ru.belchenkoa.gts3diag;

import android.app.Activity;
import android.os.*;
import android.view.*;
import android.widget.*;
import java.io.*;
import java.text.SimpleDateFormat;
import java.util.*;

public class MainActivity extends Activity {
    private TextView status;
    @Override public void onCreate(Bundle b) {
        super.onCreate(b);
        LinearLayout l=new LinearLayout(this); l.setOrientation(LinearLayout.VERTICAL); l.setPadding(28,28,28,28);
        TextView h=new TextView(this); h.setText("GTS3 Diagnostics"); h.setTextSize(26); l.addView(h);
        TextView d=new TextView(this); d.setText("\nОдин клик собирает полный текстовый отчёт. При наличии Magisk будет запрошен root; без root собирается доступная часть.\n"); d.setTextSize(16); l.addView(d);
        Button run=new Button(this); run.setText("СОБРАТЬ ПОЛНЫЙ ОТЧЁТ"); l.addView(run);
        status=new TextView(this); status.setText("\nГотово."); status.setTextIsSelectable(true); l.addView(status);
        setContentView(l); run.setOnClickListener(v -> new Thread(this::collect).start());
    }
    private void collect() {
        runOnUiThread(() -> status.setText("\nСбор диагностики… Если Magisk спросит root — разрешите."));
        String ts=new SimpleDateFormat("yyyyMMdd-HHmmss",Locale.US).format(new Date());
        String out="/sdcard/Download/gts3diag-"+ts+".txt";
        try {
            File script=new File(getFilesDir(),"gts3diag.sh");
            try(FileOutputStream f=new FileOutputStream(script)){f.write(SCRIPT.getBytes("UTF-8"));}
            script.setExecutable(true,false);
            Process p;
            try { p=new ProcessBuilder("su","-c","sh '"+script.getAbsolutePath()+"' > '"+out+"' 2>&1").redirectErrorStream(true).start(); p.waitFor(); }
            catch(Exception rootFail) { p=new ProcessBuilder("sh","-c","sh '"+script.getAbsolutePath()+"' > '"+out+"' 2>&1").redirectErrorStream(true).start(); p.waitFor(); }
            final int code=p.exitValue();
            runOnUiThread(() -> status.setText("\nГотово. Код: "+code+"\nФайл:\n"+out+"\n\nПришлите этот один TXT в чат."));
        } catch(Exception e) { runOnUiThread(() -> status.setText("\nОшибка: "+e)); }
    }
    private static final String SCRIPT =
"#!/system/bin/sh\n"+
"section(){ echo; echo '================================================================================'; echo \"### $1\"; echo '================================================================================'; }\n"+
"run(){ section \"$1\"; shift; \"$@\" 2>&1 || echo \"[exit=$?]\"; }\n"+
"echo 'GTS3 DIAGNOSTICS'; date; echo model=$(getprop ro.product.model); echo device=$(getprop ro.product.device); echo fingerprint=$(getprop ro.build.fingerprint); echo kernel=$(uname -a); echo uptime=$(cat /proc/uptime)\n"+
"run SELINUX_GETENFORCE getenforce\n"+
"section SELINUX_FS; mount | grep -i selinux; ls -ldZ /sys/fs/selinux /sys/fs/selinux/enforce 2>&1; cat /sys/fs/selinux/enforce 2>&1; cat /proc/cmdline\n"+
"section SELINUX_POLICY; ls -lZ /vendor/etc/selinux /system/etc/selinux 2>&1; dmesg | grep -iE 'selinux|avc|policy'\n"+
"run GETPROP getprop\n"+
"run KERNEL_DMESG dmesg\n"+
"run LOGCAT logcat -b all -d -v threadtime\n"+
"run MOUNTS cat /proc/mounts\n"+
"run FILESYSTEMS cat /proc/filesystems\n"+
"run DF df -h\n"+
"section BLOCK; cat /proc/partitions; ls -l /dev/block/by-name /dev/block/bootdevice/by-name 2>&1\n"+
"section USB_SYSFS; for d in /sys/bus/usb/devices/*; do echo ==== $d; cat $d/uevent 2>/dev/null; done\n"+
"run DUMPSYS_USB dumpsys usb\n"+
"run DUMPSYS_MOUNT dumpsys mount\n"+
"section STORAGE; ls -la /storage /mnt/media_rw /mnt/runtime/default /mnt/runtime/read /mnt/runtime/write 2>&1\n"+
"section POWER_SUPPLY; for d in /sys/class/power_supply/*; do echo ==== $d; for f in $d/*; do [ -f $f ] && echo $(basename $f)=$(cat $f 2>/dev/null); done; done\n"+
"run DUMPSYS_BATTERY dumpsys battery\n"+
"run DUMPSYS_POWER dumpsys power\n"+
"section THERMAL; for f in /sys/class/thermal/thermal_zone*/{type,temp}; do echo $f=$(cat $f 2>/dev/null); done\n"+
"run CAMERA dumpsys media.camera\n"+
"run MEDIA_CODEC dumpsys media.codec\n"+
"run MEDIA_EXTRACTOR dumpsys media.extractor\n"+
"run MEDIA_METRICS dumpsys media.metrics\n"+
"run DISPLAY dumpsys display\n"+
"run INPUT dumpsys input\n"+
"run AUDIO dumpsys audio\n"+
"run WIFI dumpsys wifi\n"+
"run BLUETOOTH dumpsys bluetooth_manager\n"+
"run TELEPHONY dumpsys telephony.registry\n"+
"run CONNECTIVITY dumpsys connectivity\n"+
"run PACKAGE dumpsys package\n"+
"run ACTIVITY dumpsys activity processes\n"+
"run SERVICES service list\n"+
"run LSHAL lshal\n"+
"run PS ps -A -Z\n"+
"run MEMINFO cat /proc/meminfo\n"+
"run CPUINFO cat /proc/cpuinfo\n"+
"run INTERRUPTS cat /proc/interrupts\n"+
"section KERNEL_CONFIG; zcat /proc/config.gz 2>&1 | grep -E 'SELINUX|SECURITY|USB|FAT|EXFAT|NTFS|FUSE'\n"+
"section FSTAB; cat /vendor/etc/fstab* /system/etc/fstab* /fstab.* 2>&1\n"+
"section MAGISK; magisk -v 2>&1; magisk --sqlite 'select * from settings;' 2>&1; ls -laZ /data/adb /data/adb/modules 2>&1\n"+
"section END; date; echo 'END GTS3 DIAGNOSTICS'\n";
}
