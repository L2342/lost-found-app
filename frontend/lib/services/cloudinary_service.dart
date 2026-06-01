import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Servicio de imágenes — sube a Cloudinary, retorna URL pública.
/// Jarol lo usa al crear o editar un reporte.
class CloudinaryService {
  // ─── Configuración ────────────────────────────────────────────
  static const String _cloudName   = 'dkes89hg6';
  static const String _uploadPreset = 'reportes_app'; // unsigned preset

  // ─── Singleton ───────────────────────────────────────────────
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  // ─── Método principal ─────────────────────────────────────────

  /// Sube una imagen a Cloudinary.
  /// Retorna la URL pública (https://...) o null si falla.
  ///
  /// Uso en el formulario de reporte (Jarol):
  /// ```dart
  /// final picked = await ImagePicker().pickImage(
  ///   source: ImageSource.gallery,
  ///   imageQuality: 70,   // reduce el peso de la imagen
  /// );
  /// if (picked == null) return;
  ///
  /// setState(() => _uploading = true);
  /// final url = await CloudinaryService().uploadImage(File(picked.path));
  /// setState(() => _uploading = false);
  ///
  /// if (url == null) {
  ///   ScaffoldMessenger.of(context).showSnackBar(
  ///     const SnackBar(content: Text('No se pudo subir la imagen')),
  ///   );
  ///   return;
  /// }
  /// // guardar url en estado local y pasarla al ReportService.create()
  /// setState(() => _imagenUrl = url);
  /// ```
  Future<String?> uploadImage(File imageFile) async {
    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(
          await http.MultipartFile.fromPath('file', imageFile.path),
        );

      final response = await request.send();
      final body    = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final json = jsonDecode(body) as Map<String, dynamic>;
        return json['secure_url'] as String?;
      }

      return null;
    } catch (_) {
      return null;
    }
  }
}