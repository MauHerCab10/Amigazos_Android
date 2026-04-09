import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';
import '../home/guayabita_home.dart';

//StatefulWidget, porque necesito manejar estados (errores, inputs, etc)
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool ocultarPassword = true;

  bool get formularioValido {
    final e = _emailController.text.trim();
    final p = _passwordController.text.trim();

    return e.isNotEmpty && emailValido(e) && p.isNotEmpty;
  }

  String? error;
  bool cargando = false;

  @override
  void initState() {
    super.initState();

    _emailController.addListener(() {
      setState(() {});
    });

    _passwordController.addListener(() {
      setState(() {});
    });
  }

  Future<void> login() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      //Intenta iniciar sesión en Firebase con el email y contraseña ingresados
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        //Redirige a la pantalla de 'Bienvenido' (GuayabitaHome)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const GuayabitaHome()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'invalid-credential') {
          error = 'Email y/o Contraseña incorrectos';
        } else {
          error = 'Error al iniciar sesión: ${e.message ?? e.code}';
        }
      });
    } catch (e) {
      setState(() {
        error = 'Credenciales de acceso inválidas: $e';
      });
    } finally {
      setState(() {
        cargando = false;
      });
    }
  }

  Future<void> register() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      //Crea al usuario en Firebase con el email y contraseña ingresados
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'email-already-in-use') {
          error = 'Ya existe una cuenta con ese email';
        } else if (e.code == 'weak-password') {
          error = 'La contraseña es muy débil';
        } else if (e.code == 'invalid-email') {
          error = 'Formato de email inválido';
        } else {
          error = 'Error al registrar usuario: ${e.message ?? e.code}';
        }
      });
    } catch (e) {
      setState(() {
        error = 'Error al registrar usuario';
      });
    } finally {
      setState(() {
        cargando = false;
      });
    }
  }

  @override
  //Construcción de la UI de Login
  Widget build(BuildContext context) {
    //Scaffold: esqueleto de la estructura visual básica de la pantalla con Material Design
    return Scaffold(
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
                    //Ícono de candado para representar la seguridad y autenticación de la pantalla de Login/Register
                    const Icon(
                      Icons.lock_outline,
                      size: 70,
                      color: Color(0xFF2575FC),
                    ),

                    const SizedBox(height: 15),

                    const Text(
                      "Amigazos",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      "Inicia sesión para continuar",
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                    ),

                    const SizedBox(height: 30),

                    //Campo de "Email"
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

                    //Campo de "Contraseña"
                    TextField(
                      controller: _passwordController,
                      obscureText: ocultarPassword,
                      decoration: InputDecoration(
                        labelText: "Contraseña",
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            ocultarPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              ocultarPassword = !ocultarPassword;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 5),

                    //Texto de error que se muestra si las credenciales son inválidas o si hay un error al registrar
                    if (error != null)
                      Text(
                        error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                    const SizedBox(height: 20),

                    //Botón de inicio de sesión para autenticar al usuario
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: cargando || !formularioValido ? null : login,
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
                        //Si está cargando, muestra un indicador de progreso, sino muestra el texto "Iniciar sesión"
                        child: cargando
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Iniciar sesión",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    //Enlace de registro, que al hacer click llama a la función register() para crear un nuevo usuario en Firebase
                    TextButton(
                      onPressed: cargando
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterPage(),
                                ),
                              );
                            },
                      child: const Text(
                        "¿No tienes cuenta? Regístrate aquí",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    //Enlace para recuperar contraseña, que al hacer click navega a la pantalla de recuperación de contraseña
                    TextButton(
                      onPressed: cargando
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ForgotPasswordPage(),
                                ),
                              );
                            },
                      child: const Text(
                        "¿Olvidaste tu contraseña?",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
  //Cuando el widget se destruye, se limpian los controladores de los textbox para evitar fugas de memoria
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool emailValido(String email) {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
  }
}
