# AppPerformanceProfiler

This is a lightweight profiling tool I developed to analyze the performance and behavior of a specific Android app, tailored for an internship opportunity.

## 🧰 Features

* ✅ Gathers all essential data for analyzing an **Android app**
* 🚀 Dumps output into a `performance_log.txt` file

## ⚙️ How It Works

1. **Plug your Android phone into your PC**  
   Make sure USB debugging is enabled on your device.

2. **Replace `&package`**  
   Open the script and replace `&package` with the actual package name of your app.

3. **Open your app**  
   Launch the app on your phone, then run the script in PowerShell.

4. **Log it**  
   When you're done benchmarking, press `Ctrl + C` — a `performance_log.txt` file will be generated automatically.

---

## 🔧 Prerequisites

Make sure the following are set up on your system:

- [ADB (Android Debug Bridge)](https://developer.android.com/tools/adb) installed and added to your system PATH
- USB debugging enabled on your Android device
- PowerShell (Windows) or a terminal emulator (for Linux/macOS if you adapt the script)

---

## 📄 Sample Output

The output log (`performance_log.txt`) will look something like this:

