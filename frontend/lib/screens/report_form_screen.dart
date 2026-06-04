import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';
import '../services/cloudinary_service.dart';

/// US-08 — Reportar objeto perdido
/// US-09 — Reportar objeto encontrado
/// US-10 — Editar reporte (se pasa [report] para modo edición)
///
/// Uso — crear:
///   Navigator.push(context, MaterialPageRoute(
///     builder: (_) => const ReportFormScreen(tipo: 'perdido'),
///   ));
///
/// Uso — editar:
///   Navigator.push(context, MaterialPageRoute(
///     builder: (_) => ReportFormScreen(tipo: report.tipo, report: report),
///   ));
class ReportFormScreen extends StatefulWidget {
  /// 'perdido' | 'encontrado'
  final String tipo;

  /// Si se pasa, el formulario entra en modo edición.
  final ReportModel? report;

  const ReportFormScreen({
    super.key,
    required this.tipo,
    this.report,
  });

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  // ─── Servicios ────────────────────────────────────────────────
  final _reportService = ReportService();
  final _cloudinaryService = CloudinaryService();
  final _picker = ImagePicker();

  // ─── Form ─────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tituloCtrl;
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _ubicacionCtrl;

  String? _categoria;
  String? _fecha; // YYYY-MM-DD
  String? _imagenUrl; // URL ya subida a Cloudinary
  Uint8List? _imagenLocalBytes; // preview local antes de subir

  bool _uploading = false;
  bool _saving = false;

  bool get _isEditing => widget.report != null;

  // ─── Categorías disponibles ───────────────────────────────────
  static const _categorias = [
    'electrónico',
    'ropa',
    'documento',
    'accesorio',
    'libro',
    'otro',
  ];

  // ─── Init ─────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    final r = widget.report;
    _tituloCtrl = TextEditingController(text: r?.titulo ?? '');
    _descripcionCtrl = TextEditingController(text: r?.descripcion ?? '');
    _ubicacionCtrl = TextEditingController(text: r?.ubicacion ?? '');
    _categoria = r?.categoria;
    _fecha = r?.fecha;
    _imagenUrl = r?.imagenUrl;
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _ubicacionCtrl.dispose();
    super.dispose();
  }

  // ─── Imagen ───────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    setState(() {
      _imagenLocalBytes = bytes;
      _uploading = true;
    });

    final url = await _cloudinaryService.uploadImage(picked);

    setState(() => _uploading = false);

    if (url == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _cloudinaryService.lastError ??
                'No se pudo subir la imagen. Intenta de nuevo.',
          ),
        ),
      );
      return;
    }

    setState(() => _imagenUrl = url);
  }

  // ─── Fecha ────────────────────────────────────────────────────

  Future<void> _pickFecha() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha != null ? DateTime.parse(_fecha!) : now,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() {
      _fecha =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    });
  }

  // ─── Guardar ──────────────────────────────────────────────────

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fecha == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la fecha del objeto.')),
      );
      return;
    }
    if (_categoria == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una categoría.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      if (_isEditing) {
        // US-10 — Editar
        await _reportService.update(
          widget.report!.id,
          titulo: _tituloCtrl.text,
          descripcion: _descripcionCtrl.text,
          ubicacion: _ubicacionCtrl.text,
          fecha: _fecha,
          categoria: _categoria,
          imagenUrl: _imagenUrl,
        );
      } else {
        // US-08 / US-09 — Crear
        await _reportService.create(
          tipo: widget.tipo,
          titulo: _tituloCtrl.text,
          descripcion: _descripcionCtrl.text,
          ubicacion: _ubicacionCtrl.text,
          fecha: _fecha!,
          categoria: _categoria!,
          imagenUrl: _imagenUrl,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Reporte actualizado.'
                : 'Reporte publicado correctamente.',
          ),
        ),
      );
      Navigator.pop(context, true); // true = hubo cambios
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ─── UI ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final esPerdido = widget.tipo == 'perdido';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? 'Editar reporte'
              : esPerdido
                  ? 'Reportar objeto perdido'
                  : 'Reportar objeto encontrado',
        ),
        backgroundColor:
            esPerdido ? Colors.red.shade700 : Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              // ── Imagen ──────────────────────────────────────
              _ImagenPicker(
                imagenLocalBytes: _imagenLocalBytes,
                imagenUrl: _imagenUrl,
                uploading: _uploading,
                onTap: _pickImage,
              ),
              const SizedBox(height: 24),

              // ── Título ──────────────────────────────────────
              _Campo(
                controller: _tituloCtrl,
                label: 'Nombre del objeto',
                hint: 'Ej. Audífonos Sony negros',
                maxLength: 60,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 16),

              // ── Descripción ─────────────────────────────────
              _Campo(
                controller: _descripcionCtrl,
                label: 'Descripción',
                hint: 'Detalles del objeto (color, marca, señas particulares…)',
                maxLines: 3,
                maxLength: 300,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 16),

              // ── Ubicación ───────────────────────────────────
              _Campo(
                controller: _ubicacionCtrl,
                label: 'Lugar del campus',
                hint: 'Ej. Biblioteca piso 2, Cafetería central',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 16),

              // ── Fecha ───────────────────────────────────────
              _FechaPicker(
                fecha: _fecha,
                onTap: _pickFecha,
              ),
              const SizedBox(height: 16),

              // ── Categoría ───────────────────────────────────
              DropdownButtonFormField<String>(
                initialValue: _categoria,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                ),
                hint: const Text('Selecciona una categoría'),
                items: _categorias
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _categoria = v),
                validator: (v) => v == null ? 'Selecciona una categoría' : null,
              ),
              const SizedBox(height: 32),

              // ── Botón guardar ────────────────────────────────
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: (_saving || _uploading) ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        esPerdido ? Colors.red.shade700 : Colors.green.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEditing ? 'Guardar cambios' : 'Publicar reporte',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _ImagenPicker extends StatelessWidget {
  final Uint8List? imagenLocalBytes;
  final String? imagenUrl;
  final bool uploading;
  final VoidCallback onTap;

  const _ImagenPicker({
    required this.imagenLocalBytes,
    required this.imagenUrl,
    required this.uploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (uploading) {
      content = const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 8),
          Text('Subiendo imagen…'),
        ],
      );
    } else if (imagenLocalBytes != null) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(imagenLocalBytes!, fit: BoxFit.cover),
      );
    } else if (imagenUrl != null) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(imagenUrl!, fit: BoxFit.cover),
      );
    } else {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined,
              size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text('Agregar imagen (opcional)',
              style: TextStyle(color: Colors.grey.shade500)),
        ],
      );
    }

    return GestureDetector(
      onTap: uploading ? null : onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: content,
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final int? maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;

  const _Campo({
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.maxLength,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }
}

class _FechaPicker extends StatelessWidget {
  final String? fecha;
  final VoidCallback onTap;

  const _FechaPicker({required this.fecha, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Fecha',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          fecha ?? 'Selecciona la fecha',
          style: TextStyle(
            color: fecha != null
                ? Theme.of(context).textTheme.bodyLarge?.color
                : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }
}
