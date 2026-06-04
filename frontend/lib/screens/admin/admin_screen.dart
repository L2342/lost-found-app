import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../config/app_config.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final UserService _userService = UserService();

  // ── Estado
  Map<String, dynamic>? _estadisticas;
  List<UserModel> _usuarios = [];
  bool _loadingStats = true;
  bool _loadingUsers = true;
  String? _errorStats;

  // ── Vista actual del panel
  _AdminVista _vista = _AdminVista.inicio;

  @override
  void initState() {
    super.initState();
    _cargarEstadisticas();
    _cargarUsuarios();
  }

  Future<void> _cargarEstadisticas() async {
    setState(() {
      _loadingStats = true;
      _errorStats = null;
    });
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.backendBaseUrl}/api/admin/estadisticas'),
        headers: {'Authorization': 'Bearer ${AppConfig.adminToken}'},
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        setState(() {
          _estadisticas = jsonDecode(res.body);
          _loadingStats = false;
        });
      } else {
        setState(() {
          _errorStats = 'Error del servidor (${res.statusCode})';
          _loadingStats = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorStats = 'Sin conexión al servidor';
        _loadingStats = false;
      });
    }
  }

  Future<void> _cargarUsuarios() async {
    setState(() => _loadingUsers = true);
    try {
      final lista = await _userService.getAllUsers();
      setState(() {
        _usuarios = lista;
        _loadingUsers = false;
      });
    } catch (e) {
      setState(() => _loadingUsers = false);
    }
  }

  Future<void> _eliminarUsuario(String uid, String nombre) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text('¿Eliminar a $nombre? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _userService.deleteUser(uid);
      setState(() => _usuarios.removeWhere((u) => u.uid == uid));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario eliminado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al eliminar usuario'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _vista != _AdminVista.inicio
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => setState(() => _vista = _AdminVista.inicio),
              )
            : null,
        title: const Text(
          'NØ',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {/* cerrar sesión — lo maneja Daniela */},
            icon: const Icon(Icons.logout, size: 16, color: Colors.black),
            label: const Text('cerrar Sesión',
                style: TextStyle(color: Colors.black, fontSize: 12)),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: switch (_vista) {
          _AdminVista.inicio => _buildInicio(),
          _AdminVista.estadisticas => _buildEstadisticas(),
          _AdminVista.usuarios => _buildGestionUsuarios(),
        },
      ),
    );
  }

  // ── INICIO del panel (fiel al mockup)
  Widget _buildInicio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'NØ',
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bienvenido @Admin',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              '¿Qué deseas hacer?',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 40),
            // Botón gestión de usuarios
            _adminCard(
              icon: Icons.person_outline,
              label: 'Gestión de usuarios',
              onTap: () => setState(() => _vista = _AdminVista.usuarios),
            ),
            const SizedBox(height: 16),
            // Botón métricas
            _adminCard(
              icon: Icons.tune,
              label: 'Ver métricas de la app',
              onTap: () => setState(() => _vista = _AdminVista.estadisticas),
            ),
          ],
        ),
      ),
    );
  }

  Widget _adminCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: const Color(0xFFD9D2E9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: Colors.black87),
            const SizedBox(height: 8),
            Text(label,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // ── ESTADÍSTICAS
  Widget _buildEstadisticas() {
    if (_loadingStats) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando métricas por favor espere'),
          ],
        ),
      );
    }

    if (_errorStats != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.close, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Ha ocurrido un error al cargar las métricas',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _cargarEstadisticas,
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.black),
                    child: const Text('Reintentar',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final stats = _estadisticas!;
    final totalUsuarios = stats['total_usuarios'] ?? _usuarios.length;
    final totalReportes = stats['total_reportes'] ?? 0;
    final perdidos = stats['reportes_perdidos'] ?? 0;
    final encontrados = stats['reportes_encontrados'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Estadísticas del sistema',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Resumen de la aplicación',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 20),
          // Grid de métricas
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _metricCard('Usuarios', '$totalUsuarios', Icons.people_outline,
                  Colors.indigo),
              _metricCard('Reportes', '$totalReportes', Icons.article_outlined,
                  Colors.blue),
              _metricCard(
                  'Perdidos', '$perdidos', Icons.search_off, Colors.red),
              _metricCard('Encontrados', '$encontrados',
                  Icons.check_circle_outline, Colors.green),
            ],
          ),
          const SizedBox(height: 24),
          // Sección objetos recuperados vs no recuperados
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Objetos recuperados vs no recuperados',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                _barraProgreso(
                  'Recuperados',
                  stats['recuperados'] ?? 0,
                  totalReportes,
                  Colors.green,
                ),
                const SizedBox(height: 8),
                _barraProgreso(
                  'No recuperados',
                  stats['no_recuperados'] ?? totalReportes,
                  totalReportes,
                  Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _barraProgreso(String label, int value, int total, Color color) {
    final pct = total == 0 ? 0.0 : value / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13)),
            Text('$value', style: const TextStyle(fontSize: 13)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: Colors.grey.shade200,
            color: color,
            minHeight: 10,
          ),
        ),
      ],
    );
  }

  // ── GESTIÓN DE USUARIOS
  Widget _buildGestionUsuarios() {
    if (_loadingUsers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_usuarios.isEmpty) {
      return const Center(child: Text('No hay usuarios registrados'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Text(
            '${_usuarios.length} usuarios registrados',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _usuarios.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final u = _usuarios[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFF0EFFF),
                    radius: 24,
                    child: Text(
                      u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7B6FF0)),
                    ),
                  ),
                  title: Text(u.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.email, style: const TextStyle(fontSize: 12)),
                      if (u.phone.isNotEmpty)
                        Text(u.phone,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  isThreeLine: u.phone.isNotEmpty,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Eliminar usuario',
                    onPressed: () => _eliminarUsuario(u.uid, u.name),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

enum _AdminVista { inicio, estadisticas, usuarios }
