import 'package:flutter/material.dart';

import '../../models/report_model.dart';
import '../../services/report_service.dart';

class EditReportScreen extends StatefulWidget {

  final ReportModel report;

  const EditReportScreen({
    super.key,
    required this.report,
  });

  @override
  State<EditReportScreen> createState() =>
      _EditReportScreenState();
}

class _EditReportScreenState
    extends State<EditReportScreen> {

  late TextEditingController tituloCtrl;
  late TextEditingController descripcionCtrl;
  late TextEditingController ubicacionCtrl;

  bool loading = false;

  @override
  void initState() {
    super.initState();

    tituloCtrl =
        TextEditingController(
      text: widget.report.titulo,
    );

    descripcionCtrl =
        TextEditingController(
      text: widget.report.descripcion,
    );

    ubicacionCtrl =
        TextEditingController(
      text: widget.report.ubicacion,
    );
  }

  Future<void> guardar() async {

    setState(() {
      loading = true;
    });

    try {

      await ReportService().update(
        widget.report.id,
        titulo: tituloCtrl.text,
        descripcion:
            descripcionCtrl.text,
        ubicacion:
            ubicacionCtrl.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
              Text("Reporte actualizado"),
        ),
      );

      Navigator.pop(context);

    } catch (e) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
          ),
        ),
      );
    }

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Editar reporte",
        ),
      ),
      body: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          children: [

            TextField(
              controller: tituloCtrl,
              decoration:
                  const InputDecoration(
                labelText: 'Título',
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller:
                  descripcionCtrl,
              maxLines: 4,
              decoration:
                  const InputDecoration(
                labelText:
                    'Descripción',
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller:
                  ubicacionCtrl,
              decoration:
                  const InputDecoration(
                labelText:
                    'Ubicación',
              ),
            ),

            const SizedBox(height: 25),

            ElevatedButton(
              onPressed:
                  loading
                      ? null
                      : guardar,
              child: const Text(
                'Guardar cambios',
              ),
            ),
          ],
        ),
      ),
    );
  }
}