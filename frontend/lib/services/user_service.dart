import '../models/user_model.dart';

/// Servicio de usuarios.
/// Samuel implementa los métodos.
///
/// David usa: getById (para mostrar datos del publicante en detalle)
/// Daniela usa: getById (para pantalla de perfil)
class UserService {
  // ─── Singleton ───────────────────────────────────────────────
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  // ─── Métodos ──────────────────────────────────────────────────

  /// Retorna un usuario por su uid.
  ///
  /// Ejemplo de uso (David — en pantalla de detalle):
  /// ```dart
  /// final usuario = await UserService().getById(reporte.userId);
  /// ```
  Future<UserModel?> getById(String uid) async {
    // TODO: Samuel — Firestore get documento de colección "usuarios"
    return null;
  }

  /// Actualiza datos del perfil del usuario actual.
  ///
  /// Ejemplo de uso (Daniela — en pantalla de perfil):
  /// ```dart
  /// await UserService().updateProfile(
  ///   uid: AuthService().currentUser!.uid,
  ///   name: nombreController.text,
  ///   phone: telefonoController.text,
  /// );
  /// ```
  Future<void> updateProfile({
    required String uid,
    String? name,
    String? phone,
  }) async {
    // TODO: Samuel — Firestore update documento en "usuarios"
    throw UnimplementedError('updateProfile() — pendiente Samuel');
  }

  /// Retorna todos los usuarios registrados (solo para admin).
  ///
  /// Ejemplo de uso (David — panel admin):
  /// ```dart
  /// final usuarios = await UserService().getAllUsers();
  /// ```
  Future<List<UserModel>> getAllUsers() async {
    // TODO: Samuel — Firestore get colección "usuarios"
    return [];
  }

  /// Elimina un usuario por uid (solo para admin).
  Future<void> deleteUser(String uid) async {
    // TODO: Samuel — Firestore delete + Firebase Auth deleteUser
    throw UnimplementedError('deleteUser() — pendiente Samuel');
  }
}
