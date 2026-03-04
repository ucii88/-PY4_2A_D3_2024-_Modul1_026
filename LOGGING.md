# LogBook App - Logging System Guide

## 📝 Logging Architecture

### Dual Logging Output:
1. **Console Output** (Terminal) - Real-time, visible saat `flutter run`
2. **File Logging** (dd-MM-yyyy.log) - Persistent audit trail

### Log Format:
```
[02-03-2026 09:26:42] [INFO] [mongo_service.dart] -> Koneksi berhasil
[02-03-2026 09:26:45] [VERBOSE] [auth.dart] -> User login
```

---

## 🎯 How Logging Works

### Saat Development (`flutter run`):
```
App running di iOS Simulator/Android Emulator
    ↓
LogHelper.writeLog() called
    ↓
Dual output:
├─ Console: Print ke terminal ✓ (immediately visible)
└─ File: Write ke app documents directory ✓ (persistent)
```

### Log File Location:
- **iOS Simulator:** `~/Library/Developer/CoreSimulator/Devices/<ID>/data/Containers/Data/Application/<ID>/Documents/logs/`
- **Android Emulator:** `/data/data/com.example.logbook_app/app_flutter/logs/`
- **Project Root:** `/logs/` (after export)

---

## 🚀 How to View & Export Logs

### Option 1: View Console Output (Easiest)
Logs langsung terlihat di terminal saat `flutter run`:
```bash
$ flutter run

flutter: [09:26:42][INFO][mongo_service.dart] -> INFO: Mencoba koneksi...
flutter: [09:26:45][INFO][mongo_service.dart] -> SUCCESS: Koneksi berhasil
```

### Option 2: Export from Simulator to Project
Run script untuk auto-copy logs dari simulator ke project `/logs`:
```bash
$ chmod +x export-logs.sh
$ ./export-logs.sh
```

Output:
```
🔍 Finding iOS Simulator...
📱 Using Simulator: 8E2CC847-E688-4421-90F7-AB63636BEEA7
✅ Found logs at: /var/mobile/Containers/.../logs
📤 Copying logs to project...
✅ Successfully exported logs to ./logs

📋 Log files:
-rw-r--r--  1 user  staff  4.2K Mar  2 09:26 02-03-2026.log
```

### Option 3: Manual Copy (Finder)
1. Open Finder
2. Press `Cmd + Shift + G`
3. Paste path: 
   ```
   ~/Library/Developer/CoreSimulator/Devices/[DEVICE_ID]/data/Containers/Data/Application/[APP_ID]/Documents/logs
   ```
4. Copy `.log` files ke project `/logs` folder

---

## 🔧 Configuration via .env

### LOG_LEVEL
Controls log detail level for console & file output:
```env
LOG_LEVEL=1    # ERROR only
LOG_LEVEL=2    # INFO + ERROR (default)
LOG_LEVEL=3    # VERBOSE + INFO + ERROR
```

### LOG_MUTE
Mute specific files from logging:
```env
LOG_MUTE=           # All files logged (default)
LOG_MUTE=auth.dart  # Mute auth.dart
LOG_MUTE=auth.dart,mongo_service.dart  # Mute multiple files
```

### Example .env:
```env
MONGODB_URI=mongodb+srv://admin:password@cluster.mongodb.net/db
LOG_LEVEL=3
LOG_MUTE=
```

---

## 📊 Log Levels

| Level | Color | Usage |
|-------|-------|-------|
| 1 | Red | ERROR - Important failures |
| 2 | Green | INFO - Key milestones (default) |
| 3 | Blue | VERBOSE - Detailed flow tracking |

---

## 🔍 Example Logs

### App Startup:
```
[02-03-2026 09:26:42] [INFO] [main.dart] -> .env file loaded
[02-03-2026 09:26:42] [INFO] [mongo_service.dart] -> INFO: Mencoba koneksi ke MongoDB Atlas...
[02-03-2026 09:26:45] [INFO] [mongo_service.dart] -> SUCCESS: Koneksi MongoDB & Koleksi 'logs' Siap
```

### CRUD Operations:
```
[02-03-2026 09:38:26] [INFO] [mongo_service.dart] -> SUCCESS: Log 'nsnsns' berhasil disimpan ke Cloud
[02-03-2026 09:38:26] [VERBOSE] [log_controller.dart] -> SUCCESS: 1 logs disimpan ke lokal
[02-03-2026 09:38:26] [INFO] [log_controller.dart] -> SUCCESS: Log baru 'nsnsns' ditambahkan ke Cloud dengan ID 69a4f822e239887648020023
```

---

## 📌 Summary

✅ **Logging Implementation:**
- Console output visible di terminal ✓
- File logs di app documents ✓  
- Controlled by LOG_LEVEL & LOG_MUTE ✓
- Per-date log files (dd-MM-yyyy.log) ✓

✅ **How to Submit:**
1. Run `flutter run` to generate logs
2. View console output for real-time logging
3. Run `./export-logs.sh` to copy logs to `/logs` folder
4. Submit project with `/logs/*.log` files

---

## 🐛 Troubleshooting

### Logs tidak muncul di console?
- Check LOG_LEVEL di .env (default=2)
- Check LOG_MUTE - pastikan file tidak di-mute
- Run app dengan: `flutter run` (bukan via IDE run button)

### Can't find simulator logs?
```bash
# List all simulators
xcrun simctl list devices

# Find app container
find ~/Library/Developer/CoreSimulator/Devices
```

### export-logs.sh error?
```bash
# Make script executable
chmod +x export-logs.sh

# Run with bash explicitly
bash ./export-logs.sh
```

---

## 📚 Related Files

- **Main Logger:** `lib/helpers/log_helper.dart`
- **Usage Example:** `lib/services/mongo_service.dart` (calls `LogHelper.writeLog()`)
- **Config:** `.env` file
- **Log Location:** `./logs/` (after export)
- **Export Script:** `./export-logs.sh`

