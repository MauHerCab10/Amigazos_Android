import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';
import '../../friends/pages/friends_home_page.dart';

//StatefulWidget, porque necesito manejar estados (errores, inputs, etc)
class LoginPage extends StatefulWidget {
  final String? successMessage;
  final Color? messageColor;

  const LoginPage({super.key, this.successMessage, this.messageColor});

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

    //Muestra el mensaje de éxito si el correo fue validado correctamente después de Registrarse o después de Resetear la contraseña
    if (widget.successMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.successMessage!),
              backgroundColor: widget.messageColor ?? Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      });
    }
  }

  Future<void> login() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      //Autenticación TRADICIONAL (Email y Contraseña)
      //Intenta iniciar sesión en Firebase con el email y contraseña ingresados
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      //Bloquea el acceso si el usuario no ha verificado su correo
      if (credential.user != null && !credential.user!.emailVerified) {
        await FirebaseAuth.instance.signOut();
        setState(() {
          error =
              'Debes verificar tu correo electrónico antes de iniciar sesión.';
        });
        return;
      }

      if (mounted) {
        //Redirige a la pantalla de 'Bienvenido' (FriendsHomePage)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const FriendsHomePage()),
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

  //Autenticación con GOOGLE Sign-In (OAuth)
  // Método para crear usuario e iniciar sesión con el servicio de Google
  Future<void> loginConGoogle() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      // Cerrar sesión de Google primero para forzar la selección de cuenta
      await GoogleSignIn().signOut();

      // Inicia el proceso de autenticación de Google
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Si el usuario cancela el login, no hacer nada
      if (googleUser == null) {
        setState(() {
          cargando = false;
        });
        return;
      }

      // Obtiene los detalles de autenticación de Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Crea las credenciales para Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Inicia sesión en Firebase con las credenciales de Google
      await FirebaseAuth.instance.signInWithCredential(credential);

      // Redirige a la pantalla de inicio
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const FriendsHomePage()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'account-exists-with-different-credential') {
          error = 'Ya existe una cuenta con este correo usando otro método';
        } else {
          error = 'Error al iniciar sesión con Google: ${e.message ?? e.code}';
        }
      });
    } catch (e) {
      setState(() {
        error = 'Error al iniciar sesión con Google: $e';
      });
    } finally {
      setState(() {
        cargando = false;
      });
    }
  }

  //Autenticación con MICROSOFT Sign-In (OAuth)
  // Método para crear usuario e iniciar sesión con el servicio de Microsoft
  Future<void> loginConMicrosoft() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      // Crea el proveedor de Microsoft con los scopes necesarios
      final microsoftProvider = OAuthProvider('microsoft.com');
      microsoftProvider.addScope('email');
      microsoftProvider.addScope('openid');
      microsoftProvider.addScope('profile');
      microsoftProvider.setCustomParameters({'tenant': 'common'});

      // Inicia el proceso de autenticación con Microsoft (abre el navegador)
      await FirebaseAuth.instance.signInWithProvider(microsoftProvider);

      // Redirige a la pantalla de inicio
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const FriendsHomePage()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'account-exists-with-different-credential') {
          error = 'Ya existe una cuenta con este correo usando otro método';
        } else if (e.code == 'cancelled-popup-request' ||
            e.code == 'popup-closed-by-user') {
          error = null; // El usuario canceló, no mostrar error
        } else {
          error =
              'Error al iniciar sesión con Microsoft: ${e.message ?? e.code}';
        }
      });
    } catch (e) {
      setState(() {
        error = 'Error al iniciar sesión con Microsoft: $e';
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
                    //Ícono de candado para representar la seguridad y autenticación de la pantalla de Login/Register para con los usuarios
                    const Icon(
                      Icons.lock_person, //supervised_user_circle_rounded
                      size: 70,
                      color: Color(0xFF2575FC),
                    ),

                    const SizedBox(height: 15),

                    //Título principal de la pantalla de Login/Register
                    const Text(
                      "Amigazos",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    //Subtítulo de la pantalla de Login/Register
                    const Text(
                      "Inicia sesión para continuar",
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                    ),

                    const SizedBox(height: 30),

                    // Botón de Google Sign-In
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: cargando ? null : loginConGoogle,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[300]!, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          backgroundColor: Colors.white,
                        ),
                        icon: Image.asset('assets/google_logo.png', height: 24),
                        label: const Text(
                          "Continuar con Google",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Botón de Microsoft Sign-In
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: cargando ? null : loginConMicrosoft,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[300]!, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          backgroundColor: Colors.white,
                        ),
                        icon: const _MicrosoftLogo(size: 18),
                        label: const Text(
                          "Continuar con Microsoft",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Separador "O"
                    Row(
                      children: [
                        Expanded(
                          child: Divider(thickness: 1, color: Colors.grey[400]),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            "O",
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(thickness: 1, color: Colors.grey[400]),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

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

                    const SizedBox(height: 16),

                    //Enlace de registro
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

                    //Enlace para recuperar contraseña
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

// Widget para dibujar el logo de Microsoft (4 cuadros de colores)
class _MicrosoftLogo extends StatelessWidget {
  final double size;
  const _MicrosoftLogo({this.size = 18});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _MicrosoftLogoPainter()),
    );
  }
}

// CustomPainter para dibujar el logo de Microsoft con 4 cuadros de colores (rojo, verde, azul y amarillo)
class _MicrosoftLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gap = size.width * 0.06;
    final squareSize = (size.width - gap) / 2;

    // Rojo (arriba-izquierda)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, squareSize, squareSize),
      Paint()..color = const Color(0xFFF25022),
    );
    // Verde (arriba-derecha)
    canvas.drawRect(
      Rect.fromLTWH(squareSize + gap, 0, squareSize, squareSize),
      Paint()..color = const Color(0xFF7FBA00),
    );
    // Azul (abajo-izquierda)
    canvas.drawRect(
      Rect.fromLTWH(0, squareSize + gap, squareSize, squareSize),
      Paint()..color = const Color(0xFF00A4EF),
    );
    // Amarillo (abajo-derecha)
    canvas.drawRect(
      Rect.fromLTWH(squareSize + gap, squareSize + gap, squareSize, squareSize),
      Paint()..color = const Color(0xFFFFB900),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
