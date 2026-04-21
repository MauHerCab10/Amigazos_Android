import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

// Manejador de mensajes en segundo plano (debe ser una función de nivel superior)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Mensaje recibido en segundo plano: ${message.messageId}');
  debugPrint('Título: ${message.notification?.title}');
  debugPrint('Cuerpo: ${message.notification?.body}');
}

class FirebaseMessagingService {
  static final FirebaseMessagingService _instance =
      FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Inicializar el servicio de notificaciones
  Future<void> initialize() async {
    // 1. Solicitar permisos para notificaciones
    await _requestPermission();

    // 2. Configurar notificaciones locales
    await _configureLocalNotifications();

    // 3. Obtener el token FCM
    await _getToken();

    // 4. Configurar manejadores de mensajes
    _configureMessageHandlers();

    // 5. Configurar manejador de mensajes en segundo plano
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  // Solicitar permisos de notificaciones
  Future<void> _requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint(
      'Estado de permisos de notificaciones: ${settings.authorizationStatus}',
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Usuario autorizó las notificaciones');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('Usuario autorizó notificaciones provisionales');
    } else {
      debugPrint('Usuario denegó o no aceptó permisos de notificaciones');
    }
  }

  // Configurar notificaciones locales para mostrar notificaciones en primer plano
  Future<void> _configureLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Crear canal de notificación para Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // ID del canal
      'Notificaciones Importantes', // Nombre del canal
      description: 'Este canal es usado para notificaciones importantes',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  // Obtener el token FCM del dispositivo
  Future<String?> _getToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      debugPrint('====================================');
      debugPrint('Token FCM: $token');
      debugPrint('====================================');
      debugPrint('Guarda este token para enviar notificaciones de prueba');

      // TODO: Aquí puedes guardar el token en Firestore asociado al usuario
      // await FirebaseFirestore.instance
      //     .collection('users')
      //     .doc(FirebaseAuth.instance.currentUser?.uid)
      //     .update({'fcmToken': token});

      return token;
    } catch (e) {
      debugPrint('Error al obtener token FCM: $e');
      return null;
    }
  }

  // Configurar manejadores de mensajes
  void _configureMessageHandlers() {
    // Cuando la app está en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Mensaje recibido en primer plano: ${message.messageId}');
      debugPrint('Título: ${message.notification?.title}');
      debugPrint('Cuerpo: ${message.notification?.body}');
      debugPrint('Datos: ${message.data}');

      // Mostrar notificación local cuando la app está en primer plano
      _showLocalNotification(message);
    });

    // Cuando el usuario toca una notificación y la app estaba en segundo plano
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(
        'Notificación tocada (app en segundo plano): ${message.messageId}',
      );
      _handleNotificationTap(message);
    });

    // Verificar si la app fue abierta desde una notificación
    _checkInitialMessage();
  }

  // Verificar si la app se abrió desde una notificación
  Future<void> _checkInitialMessage() async {
    RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();

    if (initialMessage != null) {
      debugPrint('App abierta desde notificación: ${initialMessage.messageId}');
      _handleNotificationTap(initialMessage);
    }
  }

  // Mostrar notificación local
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'high_importance_channel',
          'Notificaciones Importantes',
          channelDescription:
              'Este canal es usado para notificaciones importantes',
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'ticker',
          playSound: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: message.hashCode,
      title: message.notification?.title ?? 'Nueva notificación',
      body: message.notification?.body ?? '',
      notificationDetails: notificationDetails,
      payload: message.data.toString(),
    );
  }

  // Manejar cuando se toca una notificación
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Usuario tocó la notificación');
    debugPrint('Datos de la notificación: ${message.data}');

    // TODO: Aquí puedes navegar a una pantalla específica según los datos del mensaje
    // Por ejemplo:
    // if (message.data['type'] == 'chat') {
    //   navigatorKey.currentState?.push(
    //     MaterialPageRoute(builder: (context) => ChatPage(chatId: message.data['chatId']))
    //   );
    // }
  }

  // Callback cuando se toca una notificación local
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notificación local tocada: ${response.payload}');
    // TODO: Manejar navegación desde notificación local
  }

  // Método para obtener el token actual (útil para guardarlo en la base de datos)
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  // Método para refrescar el token
  void onTokenRefresh(Function(String) onNewToken) {
    _firebaseMessaging.onTokenRefresh.listen((String token) {
      debugPrint('Token FCM actualizado: $token');
      onNewToken(token);
    });
  }

  // Método público para mostrar notificaciones locales desde cualquier parte de la app
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'high_importance_channel',
          'Notificaciones Importantes',
          channelDescription:
              'Este canal es usado para notificaciones importantes',
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'ticker',
          playSound: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }
}
