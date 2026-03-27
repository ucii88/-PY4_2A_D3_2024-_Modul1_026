import 'package:flutter_dotenv/flutter_dotenv.dart';

/// AccessControlService: Gatekeeper terpusat untuk RBAC (Role-Based Access Control)
/// Mengelola perizinan akses berdasarkan role pengguna dan kepemilikan data
class AccessControlService {
  // Definisi aksi yang tersedia
  static const String actionCreate = 'create';
  static const String actionRead = 'read';
  static const String actionUpdate = 'update';
  static const String actionDelete = 'delete';

  // Definisi role yang tersedia
  static const String roleKetua = 'Ketua';
  static const String roleAnggota = 'Anggota';
  static const String roleAsisten = 'Asisten';

  /// Mengambil daftar role dari .env atau menggunakan default
  static List<String> get availableRoles =>
      dotenv.env['APP_ROLES']?.split(',') ?? [roleAnggota, roleKetua];

  /// Matriks perizinan yang fleksibel: role -> list of actions yang diizinkan
  static final Map<String, List<String>> _rolePermissions = {
    roleKetua: [actionCreate, actionRead, actionUpdate, actionDelete],
    roleAnggota: [actionCreate, actionRead],
    roleAsisten: [actionRead, actionUpdate],
  };

  /// Cek apakah pengguna dengan role tertentu dapat melakukan aksi
  ///
  /// Parameters:
  /// - role: Role pengguna ('Ketua', 'Anggota', 'Asisten')
  /// - action: Aksi yang ingin dilakukan ('create', 'read', 'update', 'delete')
  /// - isOwner: Flag untuk pengecekan kepemilikan data (penting untuk Anggota)
  ///
  /// Returns: true jika pengguna memiliki izin, false sebaliknya
  static bool canPerform(String role, String action, {bool isOwner = false}) {
    // Ambil daftar permission untuk role tersebut
    final permissions = _rolePermissions[role] ?? [];
    bool hasBasicPermission = permissions.contains(action);

    // ========== OWNERSHIP-BASED LOGIC ==========
    // DELETE: Hanya pemilik yang bisa delete (berlaku untuk semua role)
    if (action == actionDelete) {
      return isOwner;
    }

    // UPDATE: Anggota hanya bisa update jika mereka adalah pemilik data
    if (role == roleAnggota && action == actionUpdate) {
      return isOwner;
    }

    // Aksi lain mengikuti permission matrix
    return hasBasicPermission;
  }

  /// Validasi full untuk operasi dengan logging details
  /// Digunakan di level controller untuk double-check keamanan
  static Future<bool> validateAction({
    required String userRole,
    required String userId,
    required String authorId,
    required String teamId,
    required String action,
    Function(String message)? onSecurityBreach,
  }) async {
    // Cek basic permission
    final isOwner = userId == authorId;
    final hasPermission = canPerform(userRole, action, isOwner: isOwner);

    if (!hasPermission) {
      final breachMessage =
          'SECURITY BREACH: User $userId (role: $userRole) attempted unauthorized $action on item owned by $authorId';
      onSecurityBreach?.call(breachMessage);
      return false;
    }

    return true;
  }

  /// Mendapatkan daftar action yang diizinkan untuk role tertentu
  static List<String> getAllowedActions(String role) {
    return _rolePermissions[role] ?? [];
  }

  /// Helper untuk set default role (untuk testing/demo)
  static String getDefaultRole() => roleAnggota;
}
