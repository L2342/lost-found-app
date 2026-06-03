import 'package:flutter/material.dart';
import '../../models/report_model.dart';
import '../../services/report_service.dart';
import '../../widgets/report_card.dart';
import '../detail/detail_screen.dart';

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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Objetos perdidos'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
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
                  return const Center(child: Text('Error al cargar reportes'));
                }

                final todos = snapshot.data ?? [];
                final filtrados = _filtrar(todos);

                if (filtrados.isEmpty) {
                  return const Center(
                    child: Text('No se encontraron reportes'),
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
      selectedColor: Colors.indigo,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
