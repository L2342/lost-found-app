import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/report_model.dart';
import '../../services/report_service.dart';

class DetailScreen extends StatefulWidget {
  final String reportId;
  const DetailScreen({super.key, required this.reportId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final ReportService _service = ReportService(); // singleton
  ReportModel? _report;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final r = await _service.getById(widget.reportId);
      setState(() {
        _report = r;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar el reporte';
        _loading = false;
      });
    }
  }

  // US-16: WhatsApp
  Future<void> _contactarWhatsApp(String phone) async {
    final numero = phone.replaceAll(RegExp(r'[^\d]'), '');
    final uri = Uri.parse('https://wa.me/57$numero');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _report == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(_error ?? 'Reporte no encontrado')),
      );
    }

    final r = _report!;
    final esPerdido = r.tipo == 'perdido';

    return Scaffold(
      appBar: AppBar(
        title: Text(r.titulo, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen — imagenUrl es nullable en el modelo real
            (r.imagenUrl != null && r.imagenUrl!.isNotEmpty)
                ? Image.network(
                    r.imagenUrl!,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                  )
                : _imagePlaceholder(),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge tipo
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: esPerdido
                          ? Colors.red.shade100
                          : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      esPerdido ? '🔴 Perdido' : '🟢 Encontrado',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: esPerdido
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    r.titulo,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    r.descripcion,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),

                  _detalle(Icons.location_on, 'Ubicación', r.ubicacion),
                  _detalle(Icons.calendar_today, 'Fecha', r.fecha),
                  _detalle(Icons.category, 'Categoría', r.categoria),
                  // estado del reporte (activo / recuperado)
                  _detalle(Icons.info_outline, 'Estado', r.estado),

                  const Divider(),

                  const Text(
                    'Publicado por',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.indigo,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Text(r.userName, style: const TextStyle(fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Botón WhatsApp (US-16)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _contactarWhatsApp(r.userPhone),
                      icon: const Icon(Icons.chat),
                      label: const Text('Contactar por WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 250,
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
      ),
    );
  }

  Widget _detalle(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.indigo),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
