import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Servicio de subida de imágenes a Cloudinary.
/// Samuel configura las credenciales. Jarol llama uploadImage().
///
/// Jarol usa: uploadImage
class CloudinaryService {
  // ─── Configuración ────────────────────────────────────────────
  static const String _cloudName = 'dkes89hg6';
  static const String _uploadPreset = 'reportes_app';

  // ─── Singleton ───────────────────────────────────────────────
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  // ─── Métodos ──────────────────────────────────────────────────

  /// Sube una imagen a Cloudinary y retorna la URL pública.
  /// Retorna null si falla la subida.
  ///
  /// Ejemplo de uso (Jarol):
  /// ```dart
  /// // 1. El usuario selecciona imagen con image_picker
  /// final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
  /// if (picked == null) return;
  ///
  /// // 2. Subir a Cloudinary
  /// final url = await CloudinaryService().uploadImage(File(picked.path));
  /// if (url == null) {
  ///   // mostrar error
  ///   return;
  /// }
  ///
  /// // 3. Pasar la URL al crear el reporte
  /// await ReportService().create(..., imagenUrl: url);
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
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final json = jsonDecode(body);
        return json['secure_url'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
