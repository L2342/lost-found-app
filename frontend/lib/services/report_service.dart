import '../models/report_model.dart';

/// Servicio de reportes.
/// Samuel implementa los métodos. El equipo ya puede llamarlos.
///
/// Jarol usa: create, update, delete, getMyReports
/// David usa: getAll, getById
class ReportService {
  // ─── Singleton ───────────────────────────────────────────────
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  // ─── Métodos ──────────────────────────────────────────────────

  /// Crea un nuevo reporte en Firestore.
  /// Retorna el id del documento creado.
  ///
  /// Ejemplo de uso (Jarol):
  /// ```dart
  /// final id = await ReportService().create(
  ///   tipo: 'perdido',
  ///   titulo: tituloController.text,
  ///   descripcion: descController.text,
  ///   ubicacion: ubicacionController.text,
  ///   fecha: '2026-05-01',
  ///   categoria: categoriaSeleccionada,
  ///   imagenUrl: urlDeCloudinary, // puede ser null
  /// );
  /// ```
  Future<String> create({
    required String tipo,
    required String titulo,
    required String descripcion,
    required String ubicacion,
    required String fecha,
    required String categoria,
    String? imagenUrl,
  }) async {
    // TODO: Samuel — agregar a Firestore colección "reportes"
    // incluir userId, userName, userPhone desde AuthService.currentUser
    throw UnimplementedError('create() — pendiente Samuel');
  }

  /// Actualiza campos de un reporte existente.
  /// Solo pasa los campos que cambian.
  ///
  /// Ejemplo de uso (Jarol):
  /// ```dart
  /// await ReportService().update(
  ///   id: report.id,
  ///   descripcion: nuevoTexto,
  /// );
  /// ```
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
    // TODO: Samuel — Firestore update solo los campos no-null
    throw UnimplementedError('update() — pendiente Samuel');
  }

  /// Elimina un reporte por id.
  ///
  /// Ejemplo de uso (Jarol):
  /// ```dart
  /// await ReportService().delete(report.id);
  /// ```
  Future<void> delete(String id) async {
    // TODO: Samuel — Firestore delete documento
    throw UnimplementedError('delete() — pendiente Samuel');
  }

  /// Retorna un Stream de todos los reportes activos,
  /// ordenados por fecha de creación descendente.
  ///
  /// Ejemplo de uso (David):
  /// ```dart
  /// StreamBuilder<List<ReportModel>>(
  ///   stream: ReportService().getAll(),
  ///   builder: (context, snapshot) {
  ///     if (!snapshot.hasData) return CircularProgressIndicator();
  ///     final reportes = snapshot.data!;
  ///     return ListView.builder(...);
  ///   },
  /// )
  /// ```
  Stream<List<ReportModel>> getAll() {
    // TODO: Samuel — Firestore snapshots colección "reportes"
    // filtrar donde estado == "activo"
    return const Stream.empty();
  }

  /// Retorna un reporte por su id.
  ///
  /// Ejemplo de uso (David):
  /// ```dart
  /// final reporte = await ReportService().getById(reportId);
  /// ```
  Future<ReportModel?> getById(String id) async {
    // TODO: Samuel — Firestore get documento por id
    return null;
  }

  /// Retorna un Stream de los reportes del usuario actual.
  ///
  /// Ejemplo de uso (Jarol):
  /// ```dart
  /// StreamBuilder<List<ReportModel>>(
  ///   stream: ReportService().getMyReports(uid),
  ///   builder: (context, snapshot) { ... },
  /// )
  /// ```
  Stream<List<ReportModel>> getMyReports(String uid) {
    // TODO: Samuel — Firestore snapshots filtrado por userId == uid
    return const Stream.empty();
  }
}
