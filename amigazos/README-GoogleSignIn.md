# Configuración de Google Sign-In para Amigazos

Esta guía te ayudará a configurar la autenticación con Google en tu aplicación Amigazos.

## 📋 Requisitos Previos

- Tener Firebase configurado en tu proyecto
- Acceso a Firebase Console
- Acceso a Google Cloud Console

## 🔧 Pasos de Configuración

### 1. Habilitar Google Sign-In en Firebase Console

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto **amigazos-db**
3. En el menú lateral, ve a **Authentication** → **Sign-in method**
4. Busca **Google** en la lista de proveedores
5. Haz click en **Google** y luego en **Enable** (Habilitar)
6. Configura los siguientes campos:
   - **Project support email**: Ingresa tu email (el que usas para Firebase)
   - **Project public-facing name**: "Amigazos" (o el nombre que quieras mostrar)
7. Haz click en **Save** (Guardar)

### 2. Obtener el SHA-1 de tu aplicación Android

El SHA-1 es necesario para que Google Sign-In funcione en Android. Sigue estos pasos:

#### Para Debug (desarrollo):

Abre una terminal en la carpeta raíz de tu proyecto y ejecuta:

```powershell
cd android
./gradlew signingReport
```

**En Windows PowerShell:**
```powershell
cd android
.\gradlew.bat signingReport
```

Esto mostrará varios certificados. Busca la sección **Task :app:signingReport** → **Variant: debug** y copia el valor del **SHA1**.

Ejemplo:
```
Variant: debug
Config: debug
Store: C:\Users\TuUsuario\.android\debug.keystore
Alias: AndroidDebugKey
SHA1: 09:7b:6e:65:91:1a:ef:4c:57:fc:7f:ce:65:c7:9d:f4:7f:6c:c5:93
```

#### Para Release (producción):

Cuando estés listo para publicar tu app, necesitarás también el SHA-1 de tu keystore de producción:

```powershell
keytool -list -v -keystore ruta/a/tu/keystore.jks -alias tu-alias
```

### 3. Agregar SHA-1 a Firebase

1. En Firebase Console, ve a **Project Settings** (ícono de engranaje en la esquina superior izquierda)
2. En la sección **Your apps**, busca tu aplicación Android
3. Desplázate hasta **SHA certificate fingerprints**
4. Haz click en **Add fingerprint**
5. Pega el SHA-1 que copiaste anteriormente
6. Haz click en **Save**

### 4. Descargar el nuevo google-services.json

Después de agregar el SHA-1:

1. En la misma página de **Project Settings**
2. Busca tu app Android
3. Haz click en el botón **Download google-services.json**
4. Reemplaza el archivo existente en:
   ```
   android/app/google-services.json
   ```

### 5. Obtener el OAuth 2.0 Client ID (si es necesario)

En algunos casos, necesitarás configurar el Client ID manualmente:

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Selecciona tu proyecto de Firebase
3. En el menú lateral, ve a **APIs & Services** → **Credentials**
4. Verás los OAuth 2.0 Client IDs que Firebase creó automáticamente
5. Si necesitas crear uno nuevo:
   - Click en **+ CREATE CREDENTIALS** → **OAuth 2.0 Client ID**
   - Application type: **Android**
   - Name: "Amigazos Android"
   - Package name: `com.example.amigazos`
   - SHA-1: Pega el SHA-1 que obtuviste anteriormente
   - Click en **CREATE**

### 6. Configuración en el Código (Ya implementado)

El código ya está implementado en el proyecto:

- ✅ Dependencia `google_sign_in` agregada en `pubspec.yaml`
- ✅ Método `loginConGoogle()` implementado en `login_page.dart`
- ✅ Botón "Continuar con Google" agregado en la UI

### 7. Instalar las Dependencias

Ejecuta en la terminal:

```powershell
flutter pub get
```

## 🚀 Probar la Autenticación

1. Asegúrate de haber completado todos los pasos anteriores
2. Ejecuta la aplicación en un dispositivo físico o emulador
3. En la pantalla de Login, haz click en **"Continuar con Google"**
4. Selecciona una cuenta de Google
5. Deberías ser redirigido automáticamente a la pantalla principal

## ⚠️ Problemas Comunes

### Error: "PlatformException(sign_in_failed)"
- **Causa**: SHA-1 no configurado correctamente o `google-services.json` desactualizado
- **Solución**: 
  1. Verifica que agregaste el SHA-1 correcto en Firebase
  2. Descarga nuevamente el `google-services.json`
  3. Limpia el proyecto: `flutter clean` y luego `flutter pub get`

### Error: "API not enabled"
- **Causa**: La API de Google Sign-In no está habilitada en Google Cloud Console
- **Solución**:
  1. Ve a Google Cloud Console
  2. APIs & Services → Library
  3. Busca "Google Sign-In API" y habilítala

### El botón no hace nada o se cierra inmediatamente
- **Causa**: Configuración incorrecta del OAuth
- **Solución**:
  1. Verifica que el package name en Firebase coincida con el de tu app: `com.example.amigazos`
  2. Verifica el SHA-1
  3. Espera unos minutos después de hacer cambios en Firebase (puede tardar en propagarse)

### Error: "account-exists-with-different-credential"
- **Causa**: El email ya está registrado con otro método de autenticación
- **Solución**: 
  - Si el usuario ya tiene cuenta con email/contraseña, debe iniciar sesión con ese método
  - Puedes vincular cuentas usando el método `linkWithCredential` de Firebase

## 📱 Verificar en iOS (cuando sea necesario)

Para iOS, necesitarás configuraciones adicionales:

1. En Xcode, abre el archivo `Info.plist`
2. Agrega el URL Scheme desde Firebase Console
3. Habilita Google Sign-In en las capabilities

## 🔒 Seguridad

- ✅ Google Sign-In usa OAuth 2.0, un protocolo seguro
- ✅ No necesitas manejar contraseñas, Google se encarga de todo
- ✅ El token de acceso se renueva automáticamente
- ✅ Los usuarios pueden revocar el acceso desde su cuenta de Google

## 📚 Recursos Adicionales

- [Documentación oficial de google_sign_in](https://pub.dev/packages/google_sign_in)
- [Firebase Auth con Google](https://firebase.google.com/docs/auth/flutter/federated-auth)
- [Google Cloud Console](https://console.cloud.google.com/)

## ✅ Checklist de Configuración

- [ ] Google Sign-In habilitado en Firebase Console
- [ ] SHA-1 agregado en Firebase
- [ ] `google-services.json` actualizado
- [ ] Dependencias instaladas con `flutter pub get`
- [ ] App probada en dispositivo/emulador
- [ ] Login con Google funciona correctamente

---

**Nota**: Recuerda que para producción necesitarás obtener y configurar el SHA-1 de tu keystore de release, no solo el de debug.
