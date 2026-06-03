import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';
import 'auth_service.dart';

/// Servicio de reportes — implementado con Firestore.
/// Jarol usa: create, update, delete, getMyReports
/// David usa: getAll, getById
class ReportService {
  // ─── Singleton ───────────────────────────────────────────────
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference get _col => _db.collection('reportes');

  // ─── Métodos ──────────────────────────────────────────────────

  /// Crea un nuevo reporte. Retorna el id del documento creado.
  Future<String> create({
    required String tipo,
    required String titulo,
    required String descripcion,
    required String ubicacion,
    required String fecha,
    required String categoria,
    String? imagenUrl,
  }) async {
    final user = AuthService().currentUser;
    if (user == null) throw Exception('Debes iniciar sesión para publicar un reporte.');

    final data = {
      'tipo': tipo,
      'titulo': titulo.trim(),
      'descripcion': descripcion.trim(),
      'ubicacion': ubicacion.trim(),
      'fecha': fecha,
      'categoria': categoria,
      'imagenUrl': imagenUrl,
      'userId': user.uid,
      'userName': user.name,
      'userPhone': user.phone,
      'estado': 'activo',
      'createdAt': FieldValue.serverTimestamp(),
    };

    final doc = await _col.add(data);
    return doc.id;
  }

  /// Actualiza solo los campos que se pasen (no-null).
  Future<void> update(
    String id, {
    String? titulo,
    String? descripcion,
    String? ubicacion,
    String? fecha,
    String? categoria,
    String? imagenUrl,
    String? estado,
  }) async {
    final user = AuthService().currentUser;
    if (user == null) throw Exception('Debes iniciar sesión.');

    final Map<String, dynamic> data = {};
    if (titulo != null) data['titulo'] = titulo.trim();
    if (descripcion != null) data['descripcion'] = descripcion.trim();
    if (ubicacion != null) data['ubicacion'] = ubicacion.trim();
    if (fecha != null) data['fecha'] = fecha;
    if (categoria != null) data['categoria'] = categoria;
    if (imagenUrl != null) data['imagenUrl'] = imagenUrl;
    if (estado != null) data['estado'] = estado;

    if (data.isEmpty) return;
    await _col.doc(id).update(data);
  }

  /// Elimina un reporte por id.
  Future<void> delete(String id) async {
    final user = AuthService().currentUser;
    if (user == null) throw Exception('Debes iniciar sesión.');
    await _col.doc(id).delete();
  }

  /// Stream de todos los reportes activos, más recientes primero.
  /// David lo usa con StreamBuilder para el feed.
  Stream<List<ReportModel>> getAll({String? tipo, String? categoria}) {
    Query query = _col.where('estado', isEqualTo: 'activo');

    if (tipo != null) query = query.where('tipo', isEqualTo: tipo);
    if (categoria != null) query = query.where('categoria', isEqualTo: categoria);

    return query.snapshots().map((snap) {
      final items = snap.docs
          .map((doc) => ReportModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();

      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  /// Retorna un reporte por su id.
  Future<ReportModel?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return ReportModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// Stream de reportes del usuario actual (para "mis publicaciones").
  Stream<List<ReportModel>> getMyReports(String uid) {
    return _col
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snap) {
          final items = snap.docs
              .map((doc) => ReportModel.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  ))
              .toList();

          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return items;
        });
  }
}