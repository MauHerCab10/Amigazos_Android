import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordPage extends StatefulWidget {
  final String?
  oobCode; // Código "Out-Of-Band" del email para restablecer contraseña

  const ChangePasswordPage({super.key, this.oobCode});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool ocultarCurrentPassword = true;
  bool ocultarNewPassword = true;
  bool ocultarConfirmPassword = true;
  String? error;
  bool cargando = false;

  //Criterios de validación para la nueva contraseña
  bool tieneMayuscula(String p) => p.contains(RegExp(r'[A-Z]'));
  bool tieneMinuscula(String p) => p.contains(RegExp(r'[a-z]'));
  bool tieneNumero(String p) => p.contains(RegExp(r'[0-9]'));
  bool tieneSimbolo(String p) => p.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  bool tieneLongitud(String p) => p.length >= 12;

  // Detecta si la solicitud de cambio de contraseña proviene desde un correo
  bool get esResetDesdeEmail =>
      widget.oobCode != null && widget.oobCode!.isNotEmpty;

  //Validación del formulario
  bool get formularioValido {
    final newP = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    // Si es reset desde email, no requiere contraseña actual
    if (esResetDesdeEmail) {
      return newP.isNotEmpty &&
          confirm.isNotEmpty &&
          newP == confirm &&
          tieneMayuscula(newP) &&
          tieneMinuscula(newP) &&
          tieneNumero(newP) &&
          tieneSimbolo(newP) &&
          tieneLongitud(newP);
    }

    // Si no, entonces requiere contraseña actual (flujo normal)
    final current = _currentPasswordController.text;
    return current.isNotEmpty &&
        newP.isNotEmpty &&
        confirm.isNotEmpty &&
        newP == confirm &&
        tieneMayuscula(newP) &&
        tieneMinuscula(newP) &&
        tieneNumero(newP) &&
        tieneSimbolo(newP) &&
        tieneLongitud(newP);
  }

  //Fortaleza de la contraseña
  String get fortaleza {
    int puntos = 0;
    String p = _newPasswordController.text;
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
    _currentPasswordController.addListener(() => setState(() {}));
    _newPasswordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
  }

  //Función para cambiar la contraseña del usuario autenticado
  Future<void> cambiarContrasena() async {
    setState(() {
      cargando = true;
      error = null;
    });
    try {
      // Si la solicitud de reset viene desde Email: usar el código de verificación
      if (esResetDesdeEmail) {
        // Verificar que el código "oob" es válido
        try {
          await FirebaseAuth.instance.verifyPasswordResetCode(widget.oobCode!);
        } catch (e) {
          throw FirebaseAuthException(
            code: 'invalid-reset-code',
            message:
                'El enlace de reset ha expirado (1 hora). Por favor, solicita uno nuevo.',
          );
        }

        // Confirmar el reset de contraseña
        await FirebaseAuth.instance.confirmPasswordReset(
          code: widget.oobCode!,
          newPassword: _newPasswordController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contraseña cambiada exitosamente')),
          );
          Navigator.pop(context);
        }
      } else {
        // Flujo normal: cambiar contraseña estando autenticado
        final user = FirebaseAuth.instance.currentUser;
        if (user == null || user.email == null) {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'Usuario no encontrado',
          );
        }

        // Reautenticar con la contraseña actual
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _currentPasswordController.text,
        );
        await user.reauthenticateWithCredential(credential);

        // Cambiar la contraseña
        await user.updatePassword(_newPasswordController.text);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contraseña cambiada exitosamente')),
          );
          Navigator.pop(context);
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        error = e.message ?? 'Error al cambiar la contraseña';
      });
    } finally {
      setState(() => cargando = false);
    }
  }

  //Construcción de la UI de la página de Cambio de contraseña
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 84, 94, 186),
        title: const Text(
          "Cambiar contraseña",
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ),
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
                    const Text(
                      "Cambiar contraseña",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Mostrar mensaje si es reset desde email
                    if (esResetDesdeEmail)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          border: Border.all(color: Colors.blue.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Ingresa tu nueva contraseña para completar el reset',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    if (esResetDesdeEmail) const SizedBox(height: 20),

                    // Campo contraseña actual (solo si NO es reset desde email)
                    if (!esResetDesdeEmail)
                      TextField(
                        controller: _currentPasswordController,
                        obscureText: ocultarCurrentPassword,
                        decoration: InputDecoration(
                          labelText: "Contraseña actual",
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              ocultarCurrentPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () => setState(
                              () => ocultarCurrentPassword =
                                  !ocultarCurrentPassword,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),

                    if (!esResetDesdeEmail) const SizedBox(height: 15),

                    // Campo nueva contraseña
                    TextField(
                      controller: _newPasswordController,
                      obscureText: ocultarNewPassword,
                      decoration: InputDecoration(
                        labelText: "Nueva contraseña",
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            ocultarNewPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () => setState(
                            () => ocultarNewPassword = !ocultarNewPassword,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Campo confirmar nueva contraseña
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: ocultarConfirmPassword,
                      decoration: InputDecoration(
                        labelText: "Confirmar nueva contraseña",
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            ocultarConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () => setState(
                            () => ocultarConfirmPassword =
                                !ocultarConfirmPassword,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        errorText:
                            _confirmPasswordController.text.isNotEmpty &&
                                _newPasswordController.text !=
                                    _confirmPasswordController.text
                            ? "Las contraseñas no coinciden"
                            : null,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Criterios de validación para la nueva contraseña
                    _visualizacionCriterio(
                      "Mayúsculas (A-Z)",
                      tieneMayuscula(_newPasswordController.text),
                    ),
                    _visualizacionCriterio(
                      "Minúsculas (a-z)",
                      tieneMinuscula(_newPasswordController.text),
                    ),
                    _visualizacionCriterio(
                      "Número (0-9)",
                      tieneNumero(_newPasswordController.text),
                    ),
                    _visualizacionCriterio(
                      "Símbolo (!@#\$%^&*)",
                      tieneSimbolo(_newPasswordController.text),
                    ),
                    _visualizacionCriterio(
                      "Al menos 12 caracteres",
                      tieneLongitud(_newPasswordController.text),
                    ),

                    //Visualización de la fortaleza de la contraseña
                    if (_newPasswordController.text.isNotEmpty) ...[
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
                      Text(error!, style: const TextStyle(color: Colors.red)),

                    // Botón para cambiar la contraseña (deshabilitado si el formulario no es válido o si está cargando)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: cargando || !formularioValido
                            ? null
                            : cambiarContrasena,
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
                                "Cambiar contraseña",
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
}
