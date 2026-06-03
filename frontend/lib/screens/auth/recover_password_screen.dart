import 'package:flutter/material.dart';
import '../../services/auth_service.dart';


class RecoverPasswordScreen extends StatefulWidget {
  const RecoverPasswordScreen({super.key});

  @override
  State<RecoverPasswordScreen> createState() =>
      _RecoverPasswordScreenState();
}

class _RecoverPasswordScreenState
    extends State<RecoverPasswordScreen> {

  final TextEditingController emailController =
      TextEditingController();

  bool loading = false;

  Future<void> recuperar() async {
    try {
      setState(() {
        loading = true;
      });

      await AuthService().recoverPassword(
        email: emailController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Se envió un correo para recuperar la contraseña',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      appBar: AppBar(
        title: const Text('Recuperar contraseña'),
      ),

      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(24),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),

              boxShadow: const [
                BoxShadow(
                  blurRadius: 10,
                  color: Colors.black12,
                ),
              ],
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                const CircleAvatar(
                  radius: 50,
                  child: Text(
                    "🙂",
                    style: TextStyle(fontSize: 50),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Recupera tu contraseña",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Ingresa tu correo electrónico y te enviaremos un enlace de recuperación.",
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 25),

                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    hintText: "Correo electrónico",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        loading ? null : recuperar,
                    child: loading
                        ? const CircularProgressIndicator()
                        : const Text(
                            "Enviar recuperación",
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}