class ReportModel {
  final String id;
  final String tipo; // "perdido" | "encontrado"
  final String titulo;
  final String descripcion;
  final String ubicacion;
  final String fecha; // YYYY-MM-DD
  final String categoria;
  final String? imagenUrl; // URL de Cloudinary
  final String userId;
  final String userName;
  final String userPhone;
  final String estado; // "activo" | "recuperado"
  final DateTime createdAt;

  ReportModel({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.descripcion,
    required this.ubicacion,
    required this.fecha,
    required this.categoria,
    this.imagenUrl,
    required this.userId,
    required this.userName,
    required this.userPhone,
    this.estado = 'activo',
    required this.createdAt,
  });

  factory ReportModel.fromMap(Map<String, dynamic> map, String docId) {
    return ReportModel(
      id: docId,
      tipo: map['tipo'] ?? '',
      titulo: map['titulo'] ?? '',
      descripcion: map['descripcion'] ?? '',
      ubicacion: map['ubicacion'] ?? '',
      fecha: map['fecha'] ?? '',
      categoria: map['categoria'] ?? '',
      imagenUrl: map['imagenUrl'],
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhone: map['userPhone'] ?? '',
      estado: map['estado'] ?? 'activo',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tipo': tipo,
      'titulo': titulo,
      'descripcion': descripcion,
      'ubicacion': ubicacion,
      'fecha': fecha,
      'categoria': categoria,
      'imagenUrl': imagenUrl,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'estado': estado,
      'createdAt': createdAt,
    };
  }
}
