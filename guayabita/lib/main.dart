import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'auth/auth_wrapper.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:app_links/app_links.dart';
import 'auth/change_password_page.dart';
import 'dart:async';

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

// Widget principal de la App
class MyApp extends StatefulWidget {
  // Constructor de la App
  const MyApp({super.key});

  // Creo el estado para manejar la lógica de Deep Links ('App Links' para Android y 'Universal Links' para iOS)
  @override
  State<MyApp> createState() => _MyAppState();
}

// Estado de la App principal, donde se maneja la lógica de Deep Links para el reset de contraseña
class _MyAppState extends State<MyApp> {
  late StreamSubscription _deepLinkSubscription;
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _setupDeepLinkListener();
  }

  // Configuración del listener para Deep Links (App Links / Universal Links)
  void _setupDeepLinkListener() {
    _deepLinkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleDeepLink(uri);
      },
      onError: (err) {
        debugPrint('Error al escuchar deep links: $err');
      },
    );
  }

  // Manejo de Deep Links para reset de contraseña
  void _handleDeepLink(Uri uri) {
    debugPrint('Deep link recibido: $uri');
    debugPrint('Scheme: ${uri.scheme}, Host: ${uri.host}, Path: ${uri.path}');
    debugPrint('Query parameters: ${uri.queryParameters}');

    // Buscar parámetros del reset de contraseña
    final oobCode = uri
        .queryParameters['oobCode']; //(Out-Of-Band Code) Código de verificación temporal seguro de un único uso usado para completar acciones críticas basadas en la identidad del usuario por Email
    // final mode = uri.queryParameters['mode']; //Tipo de acción (en este caso, "resetPassword" para restablecer contraseña)

    // Manejar Deep Links desde la página web personalizada (Custom URL Scheme)
    if (uri.scheme == 'com.example.guayabita') {
      final webOobCode = uri.queryParameters['oobCode'];

      if (webOobCode != null && webOobCode.isNotEmpty) {
        debugPrint('Reset desde web link con oobCode: $webOobCode');
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => ChangePasswordPage(oobCode: webOobCode),
          ),
        );
        return;
      }
    }

    // Manejar Deep Links desde HTTPS y HTTP (App Links / Universal Links)
    if ((uri.scheme == 'https' || uri.scheme == 'http') &&
        oobCode != null &&
        oobCode.isNotEmpty) {
      debugPrint('Reset desde HTTPS link con oobCode: $oobCode');
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => ChangePasswordPage(oobCode: oobCode),
        ),
      );
    }
  }

  @override
  void dispose() {
    _deepLinkSubscription.cancel();
    super.dispose();
  }

  @override
  //Construcción de la App
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Amigazos',
      theme: ThemeData(),
      home: const AuthWrapper(),
      navigatorKey: navigatorKey,
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
