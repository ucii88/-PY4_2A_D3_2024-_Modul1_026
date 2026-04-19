# 🚨 Smart Patrol Vision - Road Damage Detection

Aplikasi real-time detection kerusakan jalan menggunakan computer vision dan dataset RDD-2022. Dirancang untuk tim patrol jalan dalam mengidentifikasi dan mendokumentasikan kerusakan infrastruktur jalan.

---

## 🎯 Fitur Utama

### **Vision Module (Kamera & Detection)**
- ✅ **Real-Time Camera Preview** - Live video dengan detection overlay
- ✅ **Intelligent Damage Classification** - 4 tipe kerusakan (D00, D10, D20, D40)
- ✅ **Color-Coded Detection Boxes** - Orange (D00), Yellow (D10), Pink (D20), Red (D40)
- ✅ **Torch Control** - Flash on/off untuk pencahayaan
- ✅ **Overlay Toggle** - Show/hide detection boxes
- ✅ **Photo Capture** - One-tap foto dengan metadata
- ✅ **Multi-Layer Rendering** - Glow effects, text shadow untuk professional UI
- ✅ **FPS Monitor** - Display real-time frame rate
- ✅ **Adaptive Processing** - Auto brightness/contrast adjustment
- ✅ **Permission Handling** - Smart camera permission request

### **RDD-2022 Damage Classification**
| Kode | Tipe | Warna | Severity |
|------|------|-------|----------|
| D00 | Longitudinal Crack | 🟠 Orange | Ringan |
| D10 | Transverse Crack | 🟡 Yellow | Ringan |
| D20 | Alligator Crack | 🩷 Pink | Sedang |
| D40 | Pothole | 🔴 Red | Berat |

---

## 📦 Instalasi & Build APK

### **Prerequisites**
```bash
# Install Flutter (https://flutter.dev/docs/get-started/install)
flutter --version

# Verify setup
flutter doctor
```

### **Setup Project**
```bash
# Clone dan setup
git clone <repository>
cd logbook_app
flutter pub get

# Configure environment
echo "MONGO_URI=your_uri" > .env
echo "API_KEY=your_key" >> .env
```

### **Run di Device/Emulator**
```bash
# List devices
flutter devices

# Run aplikasi
flutter run

# Run dengan verbose logging
flutter run -v
```

### **Build Release APK**
```bash
# Build APK
flutter build apk --release

# Output: build/app/outputs/apk/release/app-release.apk
# Size: ~60-80MB
```

### **Build Split APK (Optimize Size)**
```bash
# Build untuk berbagai CPU architecture
flutter build apk --split-per-abi

# Outputs:
# - app-armeabi-v7a-release.apk (~35MB)
# - app-arm64-v8a-release.apk (~40MB)
```

### **Install ke Device**
```bash
# Install APK
adb install -r build/app/outputs/apk/release/app-release.apk

# Atau double-click APK file di Android device
```

---

## 🎮 Cara Menggunakan

1. **Open Aplikasi** → Tap icon Smart Patrol Vision
2. **Grant Permission** → Allow camera access saat diminta
3. **View Preview** → Live camera feed muncul dengan detection boxes
4. **Toggle Fitur**:
   - 🔦 **Torch**: Nyalakan flash untuk cahaya
   - 🎨 **Overlay**: Toggle show/hide detections
5. **Capture** → Tap 📸 button untuk ambil foto
6. **View Result** → Foto tersimpan dengan metadata

---

## 💻 Tech Stack

- **Framework**: Flutter 3.16+
- **Language**: Dart 3.2+
- **Camera**: package:camera 0.11.0
- **Permission**: permission_handler 11.0+
- **Canvas**: CustomPaint (native rendering)
- **Min SDK**: Android 8.0 (API 26)

---

## ⚙️ Troubleshooting

**Camera tidak buka?**
```bash
# Check permissions: Settings → Apps → Smart Patrol Vision → Permissions
# Atau reset: adb shell pm reset-permissions
```

**APK build gagal?**
```bash
flutter clean
flutter pub get
flutter build apk --verbose
```

**Aplikasi lag?**
- Disable torch jika tidak diperlukan
- Reduce detection update frequency di settings
- Gunakan device dengan spesifikasi lebih tinggi

---

**Version**: 1.0.0  
**Last Updated**: April 2026



