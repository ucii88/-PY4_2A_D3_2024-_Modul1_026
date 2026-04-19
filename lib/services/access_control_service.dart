import 'package:flutter_dotenv/flutter_dotenv.dart';

class AccessControlService {
  static const String actionCreate = 'create';
  static const String actionRead = 'read';
  static const String actionUpdate = 'update';
  static const String actionDelete = 'delete';

  static const String roleKetua = 'Ketua';
  static const String roleAnggota = 'Anggota';
  static const String roleAsisten = 'Asisten';

  static List<String> get availableRoles =>
      dotenv.env['APP_ROLES']?.split(',') ?? [roleAnggota, roleKetua];

  static final Map<String, List<String>> _rolePermissions = {
    roleKetua: [actionCreate, actionRead, actionUpdate, actionDelete],
    roleAnggota: [actionCreate, actionRead],
    roleAsisten: [actionRead, actionUpdate],
  };

  static bool canPerform(String role, String action, {bool isOwner = false}) {
    final permissions = _rolePermissions[role] ?? [];
    bool hasBasicPermission = permissions.contains(action);

    if (action == actionDelete) {
      return isOwner;
    }

    if (role == roleAnggota && action == actionUpdate) {
      return isOwner;
    }

    return hasBasicPermission;
  }

  static Future<bool> validateAction({
    required String userRole,
    required String userId,
    required String authorId,
    required String teamId,
    required String action,
    Function(String message)? onSecurityBreach,
  }) async {
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

  static List<String> getAllowedActions(String role) {
    return _rolePermissions[role] ?? [];
  }
}
