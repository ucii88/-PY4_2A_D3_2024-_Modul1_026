# 📝 Aplikasi LogBook

Aplikasi mobile untuk mencatat aktivitas harian dengan kategori yang berbeda-beda. Dibuat menggunakan Flutter dengan integrasi MongoDB Atlas.

## ✨ Fitur Utama

### 🔐 **Login & Authentication**
- Login dengan username dan password
- Session management
- Interface yang user-friendly

### 📖 **LogBook (Catat Aktivitas)**
- **Tambah catatan** dengan judul dan deskripsi
- **Kategori warna-warni:**
  - 🌸 **Pribadi** - Pink
  - 💼 **Pekerjaan** - Biru  
  - 🚨 **Urgent** - Merah
- **Pencarian catatan** berdasarkan kata kunci
- **Edit & hapus** catatan
- **Sync dengan cloud** (MongoDB Atlas)
- **Mode offline** - bisa digunakan tanpa internet

### 🔢 **Counter**
- Hitung angka dengan step yang bisa diatur
- Riwayat aktivitas penambahan/pengurangan
- Reset counter dengan konfirmasi

### 🌐 **Online/Offline Support**
- **Online**: Data tersimpan di MongoDB Atlas
- **Offline**: Data tersimpan lokal, sync otomatis saat online
- **Indikator status koneksi** di header

## 🎨 **Tampilan**

- **Design modern** dengan warna pink theme
- **Card design** untuk setiap catatan
- **Kategori dengan warna berbeda** (background penuh)
- **Icon yang intuitif** untuk setiap aksi
- **Responsive design** untuk berbagai ukuran layar

## 🛠️ **Teknologi**

- **Frontend**: Flutter (Dart)
- **Database**: MongoDB Atlas 
- **State Management**: StatefulWidget
- **Local Storage**: File System
- **Package**: 
  - `flutter_dotenv` - Environment variables
  - `mongo_dart` - MongoDB integration
  - `connectivity_plus` - Network connectivity
  - `intl` - Date formatting
  - `path_provider` - File system access

## 🚀 **Setup & Installation**

### 1. Clone Repository
```bash
git clone <repository-url>
cd logbook_app
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Setup Environment
```bash
# Buat file .env di root folder
MONGODB_URI=mongodb://username:password@host:port/database
LOG_LEVEL=3
LOG_MUTE=
```

### 4. Run Application
```bash
flutter run
```

## 📱 **Cara Penggunaan**

### Login
1. Masukkan username dan password
2. Klik "Masuk" untuk masuk ke aplikasi

### Menambah Catatan
1. Klik tombol "+" di halaman LogBook
2. Isi judul dan deskripsi catatan
3. Pilih kategori (Pribadi/Pekerjaan/Urgent)
4. Klik "Simpan"

### Mencari Catatan
1. Gunakan search bar di atas
2. Ketik kata kunci yang dicari
3. Hasil akan difilter otomatis

### Counter
1. Masuk ke tab Counter
2. Tentukan step penambahan/pengurangan
3. Gunakan tombol + atau - untuk mengubah nilai
4. Lihat riwayat aktivitas di bawah

## 📂 **Struktur Folder**
```
lib/
├── main.dart                  # Entry point aplikasi
├── features/
│   ├── auth/                 # Login & authentication
│   ├── logbook/             # Fitur catatan
│   ├── counter/             # Fitur counter
│   └── onboarding/          # Welcome screen
├── services/
│   ├── mongo_service.dart   # MongoDB integration
│   └── connectivity_service.dart # Network status
├── helpers/
│   └── log_helper.dart      # Logging utility
└── models/
    └── logbook_model.dart   # Data model
```

## 🔧 **Development**

### Build untuk Release
```bash
# Android
flutter build apk --release

# iOS  
flutter build ios --release

# macOS
flutter build macos --release
```

### Debug Mode
```bash
flutter run --debug
```

## 👨‍💻 **Developer**
**uci88** - Flutter Developer

---
**© 2026 LogBook App - Aplikasi Catatan Harian** ✨
