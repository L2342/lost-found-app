import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/user_model.dart';
import '../../config/app_config.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String get _baseUrl => AppConfig.backendBaseUrl;
  String get _adminToken => AppConfig.adminToken;

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
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_adminToken',
      };

      // Carga en paralelo: estadísticas + usuarios desde backend Flask.
      final results = await Future.wait([
        http
            .get(
              Uri.parse('$_baseUrl/api/admin/estadisticas'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 10)),
        http
            .get(
              Uri.parse('$_baseUrl/api/admin/usuarios'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 10)),
      ]);

      final statsRes = results[0];
      final usersRes = results[1];

      if (statsRes.statusCode == 401 || usersRes.statusCode == 401) {
        setState(() {
          _error =
              '401 No autorizado. Verifica ADMIN_TOKEN en backend y frontend.';
          _loading = false;
        });
        return;
      }

      if (statsRes.statusCode != 200 || usersRes.statusCode != 200) {
        setState(() {
          _error =
              'Error del servidor (stats ${statsRes.statusCode}, users ${usersRes.statusCode})';
          _loading = false;
        });
        return;
      }

      final statsJson = jsonDecode(statsRes.body) as Map<String, dynamic>;
      final usersJson = jsonDecode(usersRes.body) as Map<String, dynamic>;

      final statsData = (statsJson['data'] as Map<String, dynamic>? ?? {});
      final usersData = (usersJson['data'] as Map<String, dynamic>? ?? {});
      final usersList = (usersData['usuarios'] as List<dynamic>? ?? []);

      final usuarios = usersList
          .whereType<Map<String, dynamic>>()
          .map((u) => UserModel(
                uid: u['uid'] ?? '',
                name: u['name'] ?? '',
                email: u['email'] ?? '',
                phone: u['phone'] ?? '',
                role: u['role'] ?? 'user',
                createdAt: DateTime.now(),
              ))
          .toList();

      setState(() {
        _estadisticas = statsData;
        _usuarios = usuarios;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudo conectar al servidor: $e';
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
    final totalUsuarios = stats['usuarios'] ?? _usuarios.length;
    final totalReportes = stats['reportes'] ?? 0;
    final reportesPerdidos = stats['perdidos'] ?? 0;
    final reportesEncontrados = stats['encontrados'] ?? 0;

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
