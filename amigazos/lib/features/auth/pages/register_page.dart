import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'email_verification_page.dart';
//import '../../../core/services/firebase_messaging_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool ocultarPassword = true;
  String? error;
  bool cargando = false;

  //Criterios de validación para la creación de una contraseña:
  bool tieneMayuscula(String p) => p.contains(RegExp(r'[A-Z]'));
  bool tieneMinuscula(String p) => p.contains(RegExp(r'[a-z]'));
  bool tieneNumero(String p) => p.contains(RegExp(r'[0-9]'));
  bool tieneSimbolo(String p) =>
      p.contains(RegExp(r'[-=!@#$%^&*(),._+/¿?":;{}|<>]'));
  bool tieneLongitud(String p) => p.length >= 12;

  //Validación del formulario
  bool get formularioValido {
    final e = _emailController.text.trim();
    final p = _passwordController.text;
    return e.isNotEmpty &&
        emailValido(e) &&
        tieneMayuscula(p) &&
        tieneMinuscula(p) &&
        tieneNumero(p) &&
        tieneSimbolo(p) &&
        tieneLongitud(p);
  }

  //Fortaleza de la contraseña
  String get fortaleza {
    int puntos = 0;
    String p = _passwordController.text;
    if (tieneMayuscula(p)) puntos++;
    if (tieneMinuscula(p)) puntos++;
    if (tieneNumero(p)) puntos++;
    if (tieneSimbolo(p)) puntos++;
    if (tieneLongitud(p)) puntos++;
    if (puntos <= 2) return "Débil";
    if (puntos <= 4) return "Media";
    return "Alta";
  }

  //Color según fortaleza de la contraseña
  Color get colorFortaleza => fortaleza == "Débil"
      ? Colors.red
      : (fortaleza == "Media" ? Colors.orange : Colors.green);

  //Agrega listeners para actualizar la UI al cambiar el texto de los campos
  @override
  void initState() {
    super.initState();
    _emailController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
  }

  //Función para registrar un nuevo usuario con email y contraseña
  Future<void> registrarUsuario() async {
    setState(() {
      cargando = true;
      error = null;
    });
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      //Envía el correo de verificación al usuario recién registrado
      await credential.user?.sendEmailVerification(
        ActionCodeSettings(
          url: 'https://amigazos-db.web.app/',
          handleCodeInApp: true,
          iOSBundleId: 'com.mhc.amigazos.ios',
          androidPackageName: 'com.mhc.amigazos.android',
          androidInstallApp: true,
        ),
      );

      if (mounted) {
        //Navega a la pantalla de verificación de correo
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) =>
                EmailVerificationPage(email: _emailController.text.trim()),
          ),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String mensajeError;
      if (e.code == 'email-already-in-use') {
        mensajeError = 'Esta cuenta ya existe. Por favor use otra.';
      } else {
        mensajeError = e.message ?? 'Ocurrió un error durante el registro.';
      }
      setState(() => error = mensajeError);
    } finally {
      setState(() => cargando = false);
    }
  }

  @override
  //Construcción de la UI de la página de Registro
  Widget build(BuildContext context) {
    return Scaffold(
      //AppBar
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 84, 94, 186),
        title: const Text(
          "Crear cuenta",
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ),

      //Cuerpo de la pantalla
      body: Container(
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  children: [
                    //Título del formulario
                    const Text(
                      "Únete a Amigazos",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
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

                    //Campo de "contraseña"
                    TextField(
                      controller: _passwordController,
                      obscureText: ocultarPassword,
                      decoration: InputDecoration(
                        labelText: "Contraseña",
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            ocultarPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () => setState(
                            () => ocultarPassword = !ocultarPassword,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    //Criterios de validación de la contraseña
                    _visualizacionCriterio(
                      "Mayúsculas (A-Z)",
                      tieneMayuscula(_passwordController.text),
                    ),
                    _visualizacionCriterio(
                      "Minúsculas (a-z)",
                      tieneMinuscula(_passwordController.text),
                    ),
                    _visualizacionCriterio(
                      "Número (0-9)",
                      tieneNumero(_passwordController.text),
                    ),
                    _visualizacionCriterio(
                      "Símbolo (!@#\$%^&*-=.+\"<>)",
                      tieneSimbolo(_passwordController.text),
                    ),
                    _visualizacionCriterio(
                      "Al menos 12 caracteres",
                      tieneLongitud(_passwordController.text),
                    ),

                    //Visualización de la fortaleza de la contraseña
                    if (_passwordController.text.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Fortaleza:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),

                            const SizedBox(width: 8),

                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: colorFortaleza,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                fortaleza,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    //Estilos para el mensaje de error
                    if (error != null)
                      Text(
                        error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 10),

                    //Botón de "Registrarse"
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: cargando || !formularioValido
                            ? null
                            : registrarUsuario,
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
                                "Registrarse",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
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

  //Widget para mostrar cada criterio de validación con un ícono de check o círculo
  Widget _visualizacionCriterio(String t, bool v) => Row(
    children: [
      Icon(
        v ? Icons.check_circle : Icons.circle_outlined,
        color: v ? Colors.green : Colors.grey,
        size: 16,
      ),
      Text(t, style: TextStyle(color: v ? Colors.green : Colors.grey)),
    ],
  );

  //Función para validar el formato del email usando una expresión regular (RegEx)
  bool emailValido(String email) {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
  }
}
