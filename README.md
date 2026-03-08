# Aplikasi LogBook

Aplikasi mobile untuk mencatat aktivitas harian dengan kategori yang berbeda-beda. Dibuat menggunakan Flutter dengan integrasi MongoDB Atlas.

## Fitur Utama

###  **Login & Authentication**
- Login dengan username dan password
- Session management
- Interface yang user-friendly

### **LogBook (Catat Aktivitas)**
- **Tambah catatan** dengan judul dan deskripsi
- **Kategori :**
  -  **Pribadi** 
  -  **Pekerjaan** 
  -  **Urgent** 
- **Pencarian catatan** berdasarkan kata kunci
- **Edit & hapus** catatan
- **Sync dengan cloud** (MongoDB Atlas)
- **Mode offline** - bisa digunakan tanpa internet


### **Online/Offline Support**
- **Online**: Data tersimpan di MongoDB Atlas
- **Offline**: Data tersimpan lokal, sync otomatis saat online
- **Indikator status koneksi** di header


## **Teknologi**

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



