import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Servicio de autenticación — implementado con Firebase Auth + Firestore.
/// Daniela usa: register, login, logout, recoverPassword, currentUser
class AuthService {
  // ─── Singleton ───────────────────────────────────────────────
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Estado de sesión ─────────────────────────────────────────

  /// Usuario actualmente autenticado. Null si no hay sesión.
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  /// Escucha cambios de sesión al arrancar la app.
  /// Llamar en main.dart una sola vez: AuthService().init()
  Future<void> init() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      _currentUser = await _fetchUser(firebaseUser.uid);
    }
  }

  // ─── Métodos ──────────────────────────────────────────────────

  /// Registra un nuevo usuario en Firebase Auth + Firestore.
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      // 1. Crear cuenta en Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;

      // 2. Guardar datos extra en Firestore
      final user = UserModel(
        uid: uid,
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        role: 'user',
        createdAt: DateTime.now(),
      );

      await _db.collection('usuarios').doc(uid).set(user.toMap());

      _currentUser = user;
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_authError(e.code));
    }
  }

  /// Inicia sesión con email y contraseña.
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = await _fetchUser(credential.user!.uid);
      if (user == null) throw Exception('Usuario no encontrado en la base de datos.');

      _currentUser = user;
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_authError(e.code));
    }
  }

  /// Cierra la sesión activa.
  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
  }

  /// Envía correo de recuperación de contraseña.
  Future<void> recoverPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw Exception(_authError(e.code));
    }
  }

  // ─── Interno ──────────────────────────────────────────────────

  Future<UserModel?> _fetchUser(String uid) async {
    final doc = await _db.collection('usuarios').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  String _authError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'El correo ya está registrado en la plataforma.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Credenciales inválidas. Verifica tu correo y contraseña.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'invalid-email':
        return 'El formato del correo no es válido.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde.';
      default:
        return 'Error de autenticación. Intenta nuevamente.';
    }
  }
}