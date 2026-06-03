import 'package:flutter/material.dart';
import '../../models/report_model.dart';
import '../../services/report_service.dart';
import '../../widgets/report_card.dart';
import '../detail/detail_screen.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../report_form_screen.dart';
import '../my_reports_screen.dart';
import '../admin/admin_screen.dart';
import '../profile/profile_screen.dart';


class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final ReportService _service = ReportService(); // usa el singleton
  final TextEditingController _searchCtrl = TextEditingController();

  String _query = '';
  String _filtroTipo = 'todos';

  List<ReportModel> _filtrar(List<ReportModel> lista) {
    return lista.where((r) {
      final pasaTipo = _filtroTipo == 'todos' || r.tipo == _filtroTipo;
      final q = _query.toLowerCase();
      final pasaBusqueda =
          q.isEmpty ||
          r.titulo.toLowerCase().contains(q) ||
          r.descripcion.toLowerCase().contains(q);
      return pasaTipo && pasaBusqueda;
    }).toList();
  }

  Future<void> _abrirCrearReporte() async {
    final tipo = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Crear reporte'),
              subtitle: Text('Selecciona el tipo de publicación'),
            ),
            ListTile(
              leading: const Icon(Icons.search_off, color: Colors.redAccent),
              title: const Text('Objeto perdido'),
              onTap: () => Navigator.pop(ctx, 'perdido'),
            ),
            ListTile(
              leading:
                  const Icon(Icons.inventory_2_outlined, color: Colors.green),
              title: const Text('Objeto encontrado'),
              onTap: () => Navigator.pop(ctx, 'encontrado'),
            ),
          ],
        ),
      ),
    );

    if (tipo == null || !mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportFormScreen(tipo: tipo),
      ),
    );
  }

  void _abrirMisPublicaciones() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyReportsScreen()),
    );
  }

  void _abrirAdmin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminScreen()),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().currentUser;
    final isAdmin = currentUser?.role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Objetos perdidos'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,

        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirCrearReporte,
        icon: const Icon(Icons.add),
        label: const Text('Crear reporte'),
      ),
      body: Column(
        children: [
          // Búsqueda (US-14)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Buscar por título o descripción...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Filtros (US-15)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildChip('Todos', 'todos'),
                _buildChip('Perdidos', 'perdido'),
                _buildChip('Encontrados', 'encontrado'),
              ],
            ),
          ),

          // Feed (US-12) — getAll() ya filtra solo 'activo' y ordena por createdAt
          Expanded(
            child: StreamBuilder<List<ReportModel>>(
              stream: _service
                  .getAll(), // sin parámetros: trae todos los activos
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Error al cargar reportes:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final todos = snapshot.data ?? [];
                final filtrados = _filtrar(todos);

                if (filtrados.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.inbox_outlined,
                            size: 56,
                            color: Colors.black54,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No se encontraron reportes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Publica el primero para comenzar.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton.icon(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ReportFormScreen(
                                      tipo: 'perdido',
                                    ),
                                  ),
                                ),
                                icon: const Icon(Icons.search_off),
                                label: const Text('Publicar perdido'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ReportFormScreen(
                                      tipo: 'encontrado',
                                    ),
                                  ),
                                ),
                                icon: const Icon(Icons.inventory_2_outlined),
                                label: const Text('Publicar encontrado'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filtrados.length,
                  itemBuilder: (context, index) {
                    final r = filtrados[index];
                    return ReportCard(
                      report: r,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailScreen(reportId: r.id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String value) {
    final selected = _filtroTipo == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filtroTipo = value),
      selectedColor: Colors.deepPurple,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
