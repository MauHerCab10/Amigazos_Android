import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();

  String? error;
  String? mensajeExito;
  bool cargando = false;

  bool get formularioValido {
    final email = _emailController.text.trim();
    return email.isNotEmpty && emailValido(email);
  }

  @override
  void initState() {
    super.initState();

    _emailController.addListener(() {
      setState(() {});
    });
  }

  Future<void> enviarCorreoRecuperacion() async {
    setState(() {
      cargando = true;
      error = null;
      mensajeExito = null;
    });

    try {
      // Envío del correo de recuperación usando FirebaseAuth
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      //Firebase Auth (por seguridad) NO revela si un correo está registrado o no responde como si todo estuviera bien,
      //para evitar que alguien pueda “adivinar correos” y confirmar cuentas registradas (a esto se le conoce como "Email Enumeration Protection"),
      //por eso, siempre muestro el mismo mensaje de éxito, incluso si el correo no existe o es inválido
      setState(() {
        mensajeExito =
            "Te enviamos un correo para restablecer tu contraseña. Revisa tu bandeja de entrada.";
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == "user-not-found") {
          error = "No existe una cuenta registrada con este correo.";
        } else if (e.code == "invalid-email") {
          error = "El correo ingresado no es válido.";
        } else {
          error = "Ocurrió un error. Intenta nuevamente.";
        }
      });
    } catch (e) {
      setState(() {
        error = "Error inesperado. Intenta más tarde.";
      });
    } finally {
      setState(() {
        cargando = false;
      });
    }
  }

  bool emailValido(String email) {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Recuperar contraseña",
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 84, 94, 186),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 84, 94, 186),
              Color.fromARGB(255, 210, 254, 255),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              elevation: 10,
              shadowColor: Colors.black54,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_reset,
                      size: 70,
                      color: Color(0xFF2575FC),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "Recuperar contraseña",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),

                    const SizedBox(height: 25),

                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Email",
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        errorText: _emailController.text.isEmpty
                            ? null
                            : (emailValido(_emailController.text.trim())
                                  ? null
                                  : "Email con formato inválido"),
                      ),
                    ),

                    const SizedBox(height: 15),

                    if (error != null)
                      Text(
                        error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                    if (mensajeExito != null)
                      Text(
                        mensajeExito!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: cargando || !formularioValido
                            ? null
                            : enviarCorreoRecuperacion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            69,
                            162,
                            255,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: cargando
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Enviar correo",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextButton(
                      onPressed: cargando
                          ? null
                          : () {
                              Navigator.pop(context);
                            },
                      child: const Text(
                        "Volver al Login",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
