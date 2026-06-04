import 'package:flutter/material.dart';
import '../../models/report_model.dart';
import '../../services/report_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/report_card.dart';
import '../detail/detail_screen.dart';
import '../admin/admin_screen.dart';
import '../my_reports_screen.dart';
import '../report_form_screen.dart';
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

  // ── Filtros US-15
  String _filtroFecha = 'todos'; // 'todos' | 'reciente' | 'antiguo'
  String _filtroCategoria = 'todos'; // 'todos' | categorías
  String _filtroLugar = 'todos'; // 'todos' | bloques

  // Lugares/bloques según el documento
  static const List<String> _lugares = [
    'todos',
    'Bloque A',
    'Bloque B',
    'Bloque C',
    'Bloque D',
    'Pecera',
    'Polideportivo',
    'Posgrados',
    'Carpa Roja',
  ];

  List<ReportModel> _filtrar(
    List<ReportModel> lista, {
    required String filtroCategoriaActual,
  }) {
    List<ReportModel> resultado = List.from(lista);

    // Filtro por búsqueda de texto
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      resultado = resultado
          .where((r) =>
              r.titulo.toLowerCase().contains(q) ||
              r.descripcion.toLowerCase().contains(q))
          .toList();
    }

    // Filtro por objeto/categoría
    if (filtroCategoriaActual != 'todos') {
      resultado = resultado
          .where((r) =>
              r.categoria.toLowerCase() == filtroCategoriaActual.toLowerCase())
          .toList();
    }

    // Filtro por lugar
    if (_filtroLugar != 'todos') {
      resultado = resultado
          .where((r) =>
              r.ubicacion.toLowerCase().contains(_filtroLugar.toLowerCase()))
          .toList();
    }

    // Filtro por fecha
    if (_filtroFecha == 'reciente') {
      resultado
          .sort((a, b) => _fechaDelObjeto(b).compareTo(_fechaDelObjeto(a)));
    } else if (_filtroFecha == 'antiguo') {
      resultado
          .sort((a, b) => _fechaDelObjeto(a).compareTo(_fechaDelObjeto(b)));
    }

    return resultado;
  }

  void _onNavTap(int index) {
    switch (index) {
      case 1:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MyReportsScreen()));
        break;
      case 2:
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => ProfileScreen()));
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
            const Text('🙂',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: -1,
                )),
            const Spacer(),
            if (esAdmin)
              IconButton(
                icon:
                    const Icon(Icons.admin_panel_settings, color: Colors.black),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AdminScreen())),
              ),
          ],
        ),
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
                        })
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
      body: StreamBuilder<List<ReportModel>>(
        stream: _service.getAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar reportes'));
          }

          final reportes = snapshot.data ?? [];
          final categorias = _categoriasDisponibles(reportes);
          final conteoCategorias = _conteoCategorias(reportes);
          final filtroCategoriaActual = categorias.contains(_filtroCategoria)
              ? _filtroCategoria
              : 'todos';

          final filtrados = _filtrar(
            reportes,
            filtroCategoriaActual: filtroCategoriaActual,
          );

          final hayFiltrosActivos = _filtroFecha != 'todos' ||
              filtroCategoriaActual != 'todos' ||
              _filtroLugar != 'todos';

          return Column(
            children: [
              // ── Barra de filtros (US-15)
              Container(
                color: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildDropdown(
                      label: 'Por fecha',
                      value: _filtroFecha,
                      items: const {
                        'todos': 'Por fecha',
                        'reciente': 'Más reciente',
                        'antiguo': 'Más antiguo',
                      },
                      onChanged: (v) => setState(() => _filtroFecha = v!),
                    ),
                    const SizedBox(width: 8),
                    _buildDropdown(
                      label: 'Por categoría',
                      value: filtroCategoriaActual,
                      items: {
                        for (var c in categorias)
                          c: c == 'todos'
                              ? 'Por categoría'
                              : '${_capitalizar(c)} (${conteoCategorias[c] ?? 0})'
                      },
                      onChanged: (v) => setState(() => _filtroCategoria = v!),
                    ),
                    const SizedBox(width: 8),
                    _buildDropdown(
                      label: 'Por lugar',
                      value: _filtroLugar,
                      items: {
                        for (var l in _lugares)
                          l: l == 'todos' ? 'Por lugar' : l
                      },
                      onChanged: (v) => setState(() => _filtroLugar = v!),
                    ),
                  ],
                ),
              ),

              if (hayFiltrosActivos)
                Container(
                  color: const Color(0xFFF0EFFF),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list,
                          size: 14, color: Color(0xFF7B6FF0)),
                      const SizedBox(width: 4),
                      const Text('Filtros activos',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF7B6FF0))),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() {
                          _filtroFecha = 'todos';
                          _filtroCategoria = 'todos';
                          _filtroLugar = 'todos';
                        }),
                        child: const Text('Limpiar',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7B6FF0),
                              fontWeight: FontWeight.bold,
                            )),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: filtrados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off,
                                size: 48, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(
                              _query.isNotEmpty || hayFiltrosActivos
                                  ? 'Sin resultados para estos filtros'
                                  : 'No hay reportes disponibles',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
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
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF7B6FF0),
        onPressed: () => _mostrarDialogoTipoReporte(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
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

  Widget _buildDropdown({
    required String label,
    required String value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final isActive = value != 'todos';
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF7B6FF0).withValues(alpha: 0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? const Color(0xFF7B6FF0) : Colors.grey.shade300,
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            icon: Icon(Icons.keyboard_arrow_down,
                size: 16,
                color: isActive ? const Color(0xFF7B6FF0) : Colors.grey),
            style: TextStyle(
              fontSize: 11,
              color: isActive ? const Color(0xFF7B6FF0) : Colors.black87,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
            items: items.entries
                .map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoTipoReporte(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                  child: Icon(Icons.search_off, color: Colors.red)),
              title: const Text('Objeto perdido'),
              subtitle: const Text('Perdí algo y necesito ayuda'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const ReportFormScreen(tipo: 'perdido')));
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE5FFE5),
                  child: Icon(Icons.check_circle_outline, color: Colors.green)),
              title: const Text('Objeto encontrado'),
              subtitle: const Text('Encontré algo y quiero devolverlo'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const ReportFormScreen(tipo: 'encontrado')));
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _capitalizar(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  List<String> _categoriasDisponibles(List<ReportModel> reportes) {
    final categorias = <String>{};
    for (final r in reportes) {
      final c = r.categoria.trim().toLowerCase();
      if (c.isNotEmpty) categorias.add(c);
    }

    final ordenadas = categorias.toList()..sort();
    return ['todos', ...ordenadas];
  }

  Map<String, int> _conteoCategorias(List<ReportModel> reportes) {
    final conteos = <String, int>{};
    for (final r in reportes) {
      final c = r.categoria.trim().toLowerCase();
      if (c.isEmpty) continue;
      conteos[c] = (conteos[c] ?? 0) + 1;
    }
    return conteos;
  }

  DateTime _fechaDelObjeto(ReportModel r) {
    final fecha = DateTime.tryParse(r.fecha);
    return fecha ?? r.createdAt;
  }
}
