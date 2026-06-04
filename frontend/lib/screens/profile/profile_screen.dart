import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import '../../models/report_model.dart';
import '../../widgets/report_card.dart';
import '../detail/detail_screen.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'edit_report_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final auth = AuthService();
  final reportService = ReportService();

  Future<void> _abrirEdicionPerfil() async {
    final actualizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const EditProfileScreen(),
      ),
    );

    if (actualizado == true) {
      await auth.refreshCurrentUser();
      if (!mounted) return;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text("Usuario no autenticado"),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mi Perfil"),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 45,
            child: Text(
              "🙂",
              style: TextStyle(fontSize: 40),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(user.email),
          Text(user.phone),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.edit),
            label: const Text("Editar perfil"),
            onPressed: _abrirEdicionPerfil,
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text("Cerrar sesión"),
            onPressed: () async {
              await auth.logout();

              if (!context.mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
                (_) => false,
              );
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              "Mis publicaciones",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ReportModel>>(
              stream: reportService.getMyReports(user.uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final reportes = snapshot.data!;

                if (reportes.isEmpty) {
                  return const Center(
                    child: Text(
                      "No tienes publicaciones",
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: reportes.length,
                  itemBuilder: (context, index) {
                    final reporte = reportes[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: Column(
                        children: [
                          ReportCard(
                            report: reporte,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailScreen(
                                    reportId: reporte.id,
                                  ),
                                ),
                              );
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.edit),
                                label: const Text("Editar"),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditReportScreen(
                                        report: reporte,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              TextButton.icon(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                label: const Text(
                                  "Eliminar",
                                  style: TextStyle(
                                    color: Colors.red,
                                  ),
                                ),
                                onPressed: () async {
                                  final confirmar = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text(
                                        'Eliminar reporte',
                                      ),
                                      content: const Text(
                                        '¿Seguro que deseas eliminarlo?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(
                                              context,
                                              false,
                                            );
                                          },
                                          child: const Text(
                                            'Cancelar',
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(
                                              context,
                                              true,
                                            );
                                          },
                                          child: const Text(
                                            'Eliminar',
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirmar == true) {
                                    await ReportService().delete(reporte.id);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
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
}
