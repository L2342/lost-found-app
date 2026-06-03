import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/user_model.dart';
import '../../services/user_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  static const String _baseUrl = 'https://TU_BACKEND_SAMUEL.com';

  final UserService _userService = UserService(); // singleton

  Map<String, dynamic>? _estadisticas;
  List<UserModel> _usuarios = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Carga en paralelo: estadísticas Flask + usuarios Firestore
      final results = await Future.wait([
        http
            .get(Uri.parse('$_baseUrl/api/admin/estadisticas'))
            .timeout(const Duration(seconds: 10)),
        _userService.getAllUsers(),
      ]);

      final res = results[0] as http.Response;
      final usuarios = results[1] as List<UserModel>;

      if (res.statusCode == 200) {
        setState(() {
          _estadisticas = jsonDecode(res.body);
          _usuarios = usuarios;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Error del servidor (${res.statusCode})';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'No se pudo conectar al servidor';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Administrador'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargarTodo),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _cargarTodo,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _buildContenido(),
    );
  }

  Widget _buildContenido() {
    final stats = _estadisticas!;
    final totalUsuarios = stats['total_usuarios'] ?? _usuarios.length;
    final totalReportes = stats['total_reportes'] ?? 0;
    final reportesPerdidos = stats['reportes_perdidos'] ?? 0;
    final reportesEncontrados = stats['reportes_encontrados'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Métricas generales',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _metricCard('Total usuarios', '$totalUsuarios', Colors.indigo),
              _metricCard('Total reportes', '$totalReportes', Colors.blue),
              _metricCard('Perdidos', '$reportesPerdidos', Colors.red),
              _metricCard('Encontrados', '$reportesEncontrados', Colors.green),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Usuarios registrados',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_usuarios.isEmpty)
            const Text('No hay usuarios disponibles')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _usuarios.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final u = _usuarios[index];
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.indigo,
                    child: Icon(Icons.person, color: Colors.white, size: 18),
                  ),
                  title: Text(u.name),
                  subtitle: Text(u.email),
                  trailing: Text(
                    u.phone,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _metricCard(String label, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: color.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
