import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';

class EmailVerificationPage extends StatefulWidget {
  final String email;

  const EmailVerificationPage({super.key, required this.email});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  int _cooldownSeconds = 60; //Tiempo de espera inicial de 60 segundos
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Método para iniciar el cooldown después de enviar el correo de verificación, que deshabilita el botón de reenvío durante 60 segundos para evitar Spam
  void _startCooldown() {
    setState(() {
      _canResend = false;
      _cooldownSeconds = 60;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_cooldownSeconds > 0) {
          _cooldownSeconds--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  // Construcción de la UI para la pantalla de verificación de correo, que se muestra después de un registro exitoso, pero antes de que el usuario haya verificado su Email
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 84, 94, 186),
        title: const Text(
          "Verificación de correo",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        automaticallyImplyLeading: false,
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
            padding: const EdgeInsets.all(24),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.mark_email_unread_outlined,
                      size: 70,
                      color: Color.fromARGB(255, 84, 94, 186),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "¡Revisa tu correo!",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Text(
                      "Te enviamos un correo de verificación a:",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      widget.email,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color.fromARGB(255, 84, 94, 186),
                      ),
                    ),

                    const SizedBox(height: 14),

                    Text(
                      "Haz clic en el enlace del correo para activar tu cuenta.\nUna vez verificada, podrás iniciar sesión.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: Text(
                              "Te acabamos de enviar un correo.\nRevisa tu bandeja de entrada por favor.",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.login),
                        label: const Text(
                          "Ir a Iniciar sesión",
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            84,
                            94,
                            186,
                          ),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: () async {
                          // Cerrar sesión antes de ir al login
                          await FirebaseAuth.instance.signOut();

                          if (context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                              (route) => false,
                            );
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextButton.icon(
                      icon: const Icon(
                        Icons.refresh,
                        color: Color.fromARGB(255, 84, 94, 186),
                      ),
                      label: Text(
                        _canResend
                            ? "Reenviar correo de verificación"
                            : "Reenviar en $_cooldownSeconds segundos",
                        style: TextStyle(
                          color: _canResend
                              ? const Color.fromARGB(255, 84, 94, 186)
                              : Colors.grey,
                        ),
                      ),
                      onPressed: !_canResend
                          ? null
                          : () async {
                              try {
                                final user = FirebaseAuth.instance.currentUser;

                                //Verificar que el usuario aún esté autenticado antes de intentar enviar el correo de verificación
                                if (user == null) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'No hay una sesión activa. Por favor, regístrate nuevamente.',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                  return;
                                }

                                // Enviar correo de verificación con ActionCodeSettings
                                await user.sendEmailVerification(
                                  ActionCodeSettings(
                                    url: 'https://amigazos-db.web.app/',
                                    handleCodeInApp: true,
                                    iOSBundleId: 'com.example.amigazos',
                                    androidPackageName: 'com.example.amigazos',
                                    androidInstallApp: true,
                                  ),
                                );

                                // Reiniciar el cooldown después de enviar exitosamente
                                _startCooldown();

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Correo de verificación reenviado. Revisa tu bandeja de entrada.',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } on FirebaseAuthException catch (e) {
                                if (context.mounted) {
                                  String mensaje;
                                  if (e.code == 'too-many-requests') {
                                    mensaje =
                                        'Demasiados intentos. Espera unos minutos antes de volver a intentar.';
                                  } else {
                                    mensaje =
                                        'No se pudo reenviar el correo. Intenta más tarde.';
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(mensaje),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Error inesperado. Intenta más tarde.',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
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
}
