# Configuración de Notificaciones Push - Amigazos

## ✅ Configuración Completada

Se ha implementado Firebase Cloud Messaging (FCM) en tu aplicación. Ahora la app puede recibir notificaciones push.

## 📋 Cambios Realizados

### 1. Dependencias Agregadas
- `firebase_messaging: ^15.3.3` - Para recibir notificaciones push
- `flutter_local_notifications: ^18.0.2` - Para mostrar notificaciones en primer plano

### 2. Permisos de Android
Se agregaron los siguientes permisos en `AndroidManifest.xml`:
- `POST_NOTIFICATIONS` - Para Android 13+ (obligatorio)
- `INTERNET` - Para recibir notificaciones
- `VIBRATE` - Para vibrar al recibir notificaciones
- `RECEIVE_BOOT_COMPLETED` - Para recibir notificaciones después de reiniciar

### 3. Servicio de Notificaciones
Se creó `lib/services/firebase_messaging_service.dart` que maneja:
- Solicitud de permisos
- Obtención del token FCM
- Recepción de notificaciones en primer plano, segundo plano y cuando la app está cerrada
- Mostrar notificaciones locales
- Manejo de tap en notificaciones

### 4. Inicialización en Main
El servicio se inicializa automáticamente al arrancar la app.

## 🚀 Próximos Pasos

### Paso 1: Instalar Dependencias
Ejecuta en la terminal:
```bash
flutter pub get
```

### Paso 2: Ejecutar la App
```bash
flutter run
```

### Paso 3: Obtener el Token FCM
Cuando ejecutes la app, busca en la consola un mensaje como:
```
====================================
Token FCM: [TU_TOKEN_AQUI]
====================================
```

**IMPORTANTE:** Copia y guarda este token, lo necesitarás para enviar notificaciones.

### Paso 4: Aceptar Permisos
Cuando abras la app, aparecerá un diálogo pidiendo permiso para enviar notificaciones. **Debes aceptarlo**.

## 🧪 Cómo Probar las Notificaciones

### Opción 1: Desde la Consola de Firebase (Recomendado para pruebas)

1. Ve a la [Consola de Firebase](https://console.firebase.google.com/)
2. Selecciona tu proyecto
3. En el menú lateral, ve a **Interactuar** → **Mensajería**
4. Haz clic en **"Crear primera campaña"** o **"Nueva campaña"**
5. Selecciona **"Mensajes de Firebase Notifications"**
6. Completa:
   - **Título**: Ej: "¡Hola desde Amigazos!"
   - **Texto**: Ej: "Esta es una notificación de prueba"
   - (Opcional) **Imagen**: URL de una imagen
7. Haz clic en **"Siguiente"**
8. En **"Seleccionar destinatarios"**:
   - Selecciona **"Enviar mensaje de prueba"**
   - Pega el **Token FCM** que obtuviste en el Paso 3
   - Haz clic en **"Probar"**

### Opción 2: Usando Postman o cURL

Puedes enviar una notificación directamente usando la API de FCM:

```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
-H "Authorization: key=TU_SERVER_KEY" \
-H "Content-Type: application/json" \
-d '{
  "to": "TU_TOKEN_FCM_AQUI",
  "notification": {
    "title": "Título de prueba",
    "body": "Mensaje de prueba desde cURL"
  },
  "data": {
    "type": "test",
    "customField": "valor personalizado"
  }
}'
```

**Nota:** Necesitas obtener el `Server Key` desde Firebase Console → Configuración del Proyecto → Cloud Messaging.

### Opción 3: Desde el Backend (Para Producción)

Cuando quieras enviar notificaciones desde tu backend, usa la librería oficial de Firebase Admin SDK:

**Node.js Example:**
```javascript
const admin = require('firebase-admin');

admin.messaging().send({
  token: 'TOKEN_FCM_DEL_USUARIO',
  notification: {
    title: 'Nuevo mensaje',
    body: 'Tienes un nuevo mensaje de un amigo'
  },
  data: {
    userId: '12345',
    type: 'chat'
  }
});
```

## 📱 Escenarios de Notificación

La app ahora maneja 3 escenarios:

### 1. App en Primer Plano (Abierta)
- Recibirás la notificación
- Se mostrará automáticamente como notificación local
- Verás logs en la consola

### 2. App en Segundo Plano (Minimizada)
- Recibirás la notificación
- Android/iOS mostrará la notificación automáticamente
- Al tocarla, se abrirá la app

### 3. App Cerrada
- Recibirás la notificación
- Android/iOS mostrará la notificación automáticamente
- Al tocarla, se abrirá la app

## 🔧 Personalización Adicional

### Guardar el Token en Firestore (Recomendado)

Para poder enviar notificaciones a usuarios específicos, debes guardar el token FCM en tu base de datos. Descomenta el código en `firebase_messaging_service.dart` línea ~110:

```dart
// TODO: Aquí puedes guardar el token en Firestore asociado al usuario
await FirebaseFirestore.instance
    .collection('users')
    .doc(FirebaseAuth.instance.currentUser?.uid)
    .update({'fcmToken': token});
```

### Manejar Navegación al Tocar Notificaciones

En `firebase_messaging_service.dart`, busca el método `_handleNotificationTap` (línea ~195) y agrega tu lógica de navegación:

```dart
void _handleNotificationTap(RemoteMessage message) {
  if (message.data['type'] == 'chat') {
    // Navegar a la pantalla de chat
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (context) => ChatPage(chatId: message.data['chatId']))
    );
  } else if (message.data['type'] == 'friend_request') {
    // Navegar a solicitudes de amistad
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (context) => FriendRequestsPage())
    );
  }
}
```

## 🐛 Solución de Problemas

### No aparece el diálogo de permisos
- Asegúrate de tener Android 13+ o iOS 10+
- Desinstala la app y vuelve a instalarla

### No recibo notificaciones
1. Verifica que aceptaste los permisos
2. Verifica que el token FCM sea correcto
3. Revisa los logs de la consola
4. Verifica que Firebase Cloud Messaging esté habilitado en tu proyecto

### Las notificaciones no suenan
- Verifica que el teléfono no esté en modo silencioso
- Verifica los permisos de notificaciones en la configuración del teléfono

### Error al compilar
```bash
flutter clean
flutter pub get
flutter run
```

## 📚 Recursos Adicionales

- [Documentación Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Firebase Messaging Package](https://pub.dev/packages/firebase_messaging)
- [Flutter Local Notifications Package](https://pub.dev/packages/flutter_local_notifications)

## ✨ Próximas Mejoras Sugeridas

1. **Tópicos de Notificación**: Suscribir usuarios a tópicos para enviar notificaciones masivas
2. **Notificaciones Programadas**: Programar notificaciones locales
3. **Analytics**: Rastrear cuántas notificaciones se abren
4. **Notificaciones Enriquecidas**: Agregar imágenes, botones de acción, etc.
5. **Sonidos Personalizados**: Configurar sonidos diferentes para diferentes tipos de notificaciones

---

**¡Listo!** Tu app ahora puede recibir notificaciones push. 🎉
