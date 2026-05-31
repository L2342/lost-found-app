import '../models/user_model.dart';

/// Servicio de autenticación.
/// Samuel implementa los métodos. El equipo ya puede llamarlos.
///
/// Daniela usa: register, login, logout, recoverPassword, currentUser
class AuthService {
  // ─── Singleton ───────────────────────────────────────────────
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // ─── Estado de sesión ─────────────────────────────────────────

  /// Usuario actualmente autenticado. Null si no hay sesión.
  UserModel? get currentUser {
    // TODO: Samuel — retornar usuario desde Firebase Auth + Firestore
    return null;
  }

  /// True si hay una sesión activa.
  bool get isLoggedIn => currentUser != null;

  // ─── Métodos ──────────────────────────────────────────────────

  /// Registra un nuevo usuario.
  /// Retorna el UserModel creado, o lanza Exception con mensaje legible.
  ///
  /// Ejemplo de uso (Daniela):
  /// ```dart
  /// try {
  ///   final user = await AuthService().register(
  ///     name: 'Daniela Fierro',
  ///     email: 'dfierro@unilibre.edu.co',
  ///     password: 'segura2026!',
  ///     phone: '3101234567',
  ///   );
  /// } catch (e) {
  ///   // mostrar e.toString() en el snackbar
  /// }
  /// ```
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    // TODO: Samuel — Firebase Auth createUserWithEmailAndPassword
    // luego guardar en Firestore colección "usuarios"
    throw UnimplementedError('register() — pendiente Samuel');
  }

  /// Inicia sesión con email y contraseña.
  /// Retorna el UserModel, o lanza Exception con mensaje legible.
  ///
  /// Ejemplo de uso (Daniela):
  /// ```dart
  /// try {
  ///   final user = await AuthService().login(
  ///     email: emailController.text,
  ///     password: passwordController.text,
  ///   );
  ///   Navigator.pushReplacementNamed(context, '/feed');
  /// } catch (e) {
  ///   // mostrar error
  /// }
  /// ```
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    // TODO: Samuel — Firebase Auth signInWithEmailAndPassword
    throw UnimplementedError('login() — pendiente Samuel');
  }

  /// Cierra la sesión activa.
  ///
  /// Ejemplo de uso (Daniela):
  /// ```dart
  /// await AuthService().logout();
  /// Navigator.pushReplacementNamed(context, '/login');
  /// ```
  Future<void> logout() async {
    // TODO: Samuel — Firebase Auth signOut
    throw UnimplementedError('logout() — pendiente Samuel');
  }

  /// Envía un correo de recuperación de contraseña.
  /// Lanza Exception si el email no está registrado.
  ///
  /// Ejemplo de uso (Daniela):
  /// ```dart
  /// try {
  ///   await AuthService().recoverPassword(email: emailController.text);
  ///   // mostrar "Correo enviado"
  /// } catch (e) {
  ///   // mostrar error
  /// }
  /// ```
  Future<void> recoverPassword({required String email}) async {
    // TODO: Samuel — Firebase Auth sendPasswordResetEmail
    throw UnimplementedError('recoverPassword() — pendiente Samuel');
  }
}
