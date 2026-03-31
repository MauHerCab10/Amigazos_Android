import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'auth/auth_wrapper.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  // 1. Aseguro que los widgets estén vinculados antes de iniciar Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Activa el "Wakelock" para mantener la pantalla encendida dentro de la app
  WakelockPlus.enable();

  // 3. Inicializo Firebase con las opciones del proyecto
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 4. Ejecución de la App
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  //Un 'widget' en Flutter es  como un 'componente' en Angular
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Amigazos',
      theme: ThemeData(),
      home: const AuthWrapper(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'), // English
        Locale('es', 'ES'), // Spanish
      ],
    );
  }
}
