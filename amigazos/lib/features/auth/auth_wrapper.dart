import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../friends/pages/friends_home_page.dart';
import 'pages/login_page.dart';

//clase "Guardián de Rutas" o "Enrutador Dinámico". Decide q pantalla va a ver el usuario, basándose en si ya inició sesión o no
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  //Construcción de la UI, según la autenticación actual del usuario (pantalla de Login o de Bienvenida)
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance
          .authStateChanges(), //"flujo de datos" (Stream) que Firebase emite cada vez q el estado del usuario cambia (cuando entra, cuando sale, cuando se inicializa la app)
      builder: (context, snapshot) {
        //Mientras Firebase responde...
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;
          //Si el usuario aún no ha verificado su correo, así ingrese correctamente sus credenciales, lo redirige al Login
          if (!user.emailVerified) {
            return const LoginPage();
          }
          return const FriendsHomePage(); //Usuario verificado y logueado
        }

        return const LoginPage(); //Usuario no logueado
      },
    );
  }
}
