import 'package:flutter/material.dart';
import '../../models/report_model.dart';
import '../../services/report_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/report_card.dart';
import '../detail/detail_screen.dart';
import '../admin/admin_screen.dart';
import '../profile/my_reports_screen.dart';
import '../profile/report_form_screen.dart';
import '../profile/profile_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final ReportService _service = ReportService();
  final TextEditingController _searchCtrl = TextEditingController();

  String _query = '';
  String _filtroTipo = 'todos';
  int _currentIndex = 0; // índice barra inferior

  List<ReportModel> _filtrar(List<ReportModel> lista) {
    return lista.where((r) {
      final pasaTipo = _filtroTipo == 'todos' || r.tipo == _filtroTipo;
      final q = _query.toLowerCase();
      final pasaBusqueda = q.isEmpty ||
          r.titulo.toLowerCase().contains(q) ||
          r.descripcion.toLowerCase().contains(q);
      return pasaTipo && pasaBusqueda;
    }).toList();
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    switch (index) {
      case 0:
        setState(() => _currentIndex = 0);
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyReportsScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
        break;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final bool esAdmin = user?.role == 'admin';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            // Logo "NØ" fiel al mockup
            const Text(
              'NØ',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                letterSpacing: -1,
              ),
            ),
            const Spacer(),
            if (esAdmin)
              IconButton(
                icon:
                    const Icon(Icons.admin_panel_settings, color: Colors.black),
                tooltip: 'Panel admin',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminScreen()),
                ),
              ),
          ],
        ),
        // Barra de búsqueda integrada en el AppBar como en el mockup
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Buscar por items',
                hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                prefixIcon: const Icon(Icons.menu, color: Colors.grey),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF0EFFF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),

      body: Column(
        children: [
          // Filtros tipo chip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildChip('Todos', 'todos'),
                const SizedBox(width: 8),
                _buildChip('Perdidos', 'perdido'),
                const SizedBox(width: 8),
                _buildChip('Encontrados', 'encontrado'),
              ],
            ),
          ),

          // Lista de reportes
          Expanded(
            child: StreamBuilder<List<ReportModel>>(
              stream: _service.getAll(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error al cargar reportes'));
                }
                final filtrados = _filtrar(snapshot.data ?? []);
                if (filtrados.isEmpty) {
                  return const Center(
                      child: Text('No se encontraron reportes'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
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

      // FAB — botón + para publicar reporte (como en el mockup)
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF7B6FF0),
        onPressed: () => _mostrarDialogoTipoReporte(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),

      // Barra de navegación inferior fiel al mockup
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        selectedItemColor: const Color(0xFF7B6FF0),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_outline),
            activeIcon: Icon(Icons.bookmark),
            label: 'Mis Items',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoTipoReporte(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Qué deseas reportar?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFFE5E5),
                child: Icon(Icons.search_off, color: Colors.red),
              ),
              title: const Text('Objeto perdido'),
              subtitle: const Text('Perdí algo y necesito ayuda'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ReportFormScreen(tipo: 'perdido'),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE5FFE5),
                child: Icon(Icons.check_circle_outline, color: Colors.green),
              ),
              title: const Text('Objeto encontrado'),
              subtitle: const Text('Encontré algo y quiero devolverlo'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ReportFormScreen(tipo: 'encontrado'),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, String value) {
    final selected = _filtroTipo == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filtroTipo = value),
      selectedColor: const Color(0xFF7B6FF0),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? const Color(0xFF7B6FF0) : Colors.grey.shade300,
        ),
      ),
    );
  }
}
