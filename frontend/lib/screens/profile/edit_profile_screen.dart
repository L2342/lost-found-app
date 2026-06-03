import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState
    extends State<EditProfileScreen> {

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool loading = false;

  @override
  void initState() {
    super.initState();

    final user = AuthService().currentUser;

    _nameController.text = user?.name ?? '';
    _phoneController.text = user?.phone ?? '';
  }

  Future<void> guardar() async {
    final user = AuthService().currentUser;

    if (user == null) return;

    setState(() {
      loading = true;
    });

    try {
      await UserService().updateProfile(
        uid: user.uid,
        name: _nameController.text,
        phone: _phoneController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Perfil actualizado',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
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
          'Editar perfil',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed:
                  loading ? null : guardar,
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