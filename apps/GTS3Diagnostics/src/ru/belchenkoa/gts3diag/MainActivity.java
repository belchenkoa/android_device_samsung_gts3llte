package ru.belchenkoa.gts3diag;

import android.app.Activity;
import android.os.Bundle;
import android.graphics.Typeface;
import android.widget.*;
import java.io.*;
import java.text.SimpleDateFormat;
import java.util.*;

public class MainActivity extends Activity {
    private TextView status;
    private Button collect;

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(32, 32, 32, 32);

        TextView title = new TextView(this);
        title.setText("GTS3 Diagnostics");
        title.setTextSize(26);
        title.setTypeface(null, Typeface.BOLD);
        root.addView(title);

        TextView info = new TextView(this);
        info.setText("\nСобирает полный диагностический отчёт прошивки через встроенный gts3diag. Для полного отчёта нужен root: после проверки загрузки установи Magisk вручную и разреши root этому приложению.\n\nОтчёт сохраняется в Download и может содержать технические идентификаторы устройства/сети.\n");
        info.setTextSize(16);
        root.addView(info);

        collect = new Button(this);
        collect.setText("Собрать полный отчёт");
        root.addView(collect);

        status = new TextView(this);
        status.setText("\nГотово к сбору.");
        status.setTextIsSelectable(true);
        root.addView(status);

        setContentView(root);
        collect.setOnClickListener(v -> startCollection());
    }

    private void startCollection() {
        collect.setEnabled(false);
        status.setText("\nСбор данных… если установлен Magisk, подтверди root-запрос.");
        new Thread(() -> {
            String ts = new SimpleDateFormat("yyyyMMdd-HHmmss", Locale.US).format(new Date());
            String path = "/sdcard/Download/gts3diag-" + ts + ".txt";
            String output;
            int rc;
            try {
                Process p = new ProcessBuilder("su", "-c", "/system/bin/gts3diag --save " + path + " all")
                        .redirectErrorStream(true).start();
                output = readAll(p.getInputStream());
                rc = p.waitFor();
            } catch (Exception e) {
                output = e.toString();
                rc = -1;
            }
            final int result = rc;
            final String text = output;
            runOnUiThread(() -> {
                collect.setEnabled(true);
                if (result == 0) {
                    status.setText("\nГотово.\n" + path + "\n\nПришли этот TXT мне целиком.");
                } else {
                    status.setText("\nRoot недоступен или отчёт не собран (exit=" + result + ").\n"
                            + "До установки Magisk можно запустить диагностику через adb root:\n"
                            + "adb root && adb shell gts3diag --save /sdcard/Download/gts3diag.txt all\n\n"
                            + text);
                }
            });
        }).start();
    }

    private String readAll(InputStream in) throws IOException {
        BufferedReader r = new BufferedReader(new InputStreamReader(in));
        StringBuilder b = new StringBuilder();
        String line;
        while ((line = r.readLine()) != null) b.append(line).append('\n');
        return b.toString();
    }
}
