import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Servicio de usuarios — implementado con Firestore.
/// David usa: getById (datos del publicante en detalle)
/// Daniela usa: updateProfile (pantalla de perfil)
class UserService {
  // ─── Singleton ───────────────────────────────────────────────
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference get _col => _db.collection('usuarios');

  // ─── Métodos ──────────────────────────────────────────────────

  /// Retorna un usuario por su uid.
  /// David lo usa en la pantalla de detalle para mostrar datos del publicante.
  Future<UserModel?> getById(String uid) async {
    final doc = await _col.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  /// Actualiza nombre y/o teléfono del perfil.
  /// Daniela lo usa en la pantalla de editar perfil.
  Future<void> updateProfile({
    required String uid,
    String? name,
    String? phone,
  }) async {
    final Map<String, dynamic> data = {};
    if (name != null && name.trim().isNotEmpty) data['name'] = name.trim();
    if (phone != null && phone.trim().isNotEmpty) data['phone'] = phone.trim();
    if (data.isEmpty) return;
    await _col.doc(uid).update(data);
  }

  /// Retorna todos los usuarios — solo para el panel admin (David).
  Future<List<UserModel>> getAllUsers() async {
    final snap = await _col.orderBy('createdAt', descending: true).get();
    return snap.docs
        .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Elimina un usuario de Firestore — solo para admin.
  /// Nota: esto borra el documento pero NO la cuenta de Firebase Auth.
  /// Para borrar Auth necesita Firebase Admin SDK (backend Flask).
  Future<void> deleteUser(String uid) async {
    await _col.doc(uid).delete();
  }
}