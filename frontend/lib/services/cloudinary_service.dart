import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

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

  String? _lastError;
  String? get lastError => _lastError;

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
  Future<String?> uploadImage(XFile imageFile) async {
    try {
      _lastError = null;

      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );

      final bytes = await imageFile.readAsBytes();
      final fileName = imageFile.name.isNotEmpty ? imageFile.name : 'reporte.jpg';

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: fileName),
        );

      final response = await request.send().timeout(const Duration(seconds: 30));
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final json = jsonDecode(body) as Map<String, dynamic>;
        return json['secure_url'] as String?;
      }

      String message = 'Error de Cloudinary (${response.statusCode}).';
      try {
        final json = jsonDecode(body) as Map<String, dynamic>;
        final error = json['error'];
        if (error is Map && error['message'] != null) {
          message = 'Cloudinary: ${error['message']}';
        }
      } catch (_) {}

      _lastError = message;

      return null;
    } on TimeoutException {
      _lastError = 'La subida tardó demasiado. Verifica tu conexión e intenta otra vez.';
      return null;
    } catch (e) {
      _lastError = 'No se pudo subir la imagen: $e';
      return null;
    }
  }
}