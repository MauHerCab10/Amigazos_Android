# Guía para Poner Amigazos en Producción

Esta guía detalla todos los pasos necesarios para publicar la aplicación Amigazos en Google Play Store.

## 📋 Checklist General

- [ ] Cambiar Application ID
- [ ] Crear Keystore para firma
- [ ] Configurar firma de la aplicación
- [ ] Actualizar versión de la app
- [ ] Configurar Firebase para producción
- [ ] Generar App Bundle firmado
- [ ] Preparar assets para Google Play Store
- [ ] Publicar en Google Play Console

---

## 1️⃣ Cambiar Application ID

**⚠️ IMPORTANTE:** Actualmente tu app usa `com.example.amigazos`, que es un ID de ejemplo y debe cambiarse.

### Paso 1.1: Elegir un Application ID único
Formato recomendado: `com.tuempresa.amigazos` o `com.tunombre.amigazos`

Ejemplo: `com.mhc.amigazos`

### Paso 1.2: Actualizar android/app/build.gradle.kts
```kotlin
defaultConfig {
    applicationId = "com.mhc.amigazos"  // Cambiar aquí
    minSdk = flutter.minSdkVersion
    targetSdk = flutter.targetSdkVersion
    versionCode = flutter.versionCode
    versionName = flutter.versionName
}
```

### Paso 1.3: Actualizar archivos de configuración
Actualizar los siguientes archivos con el nuevo Application ID:
- `android/app/src/main/AndroidManifest.xml`
- Cualquier configuración de Deep Links
- Firebase console (agregar nueva app con el nuevo package name)

---

## 2️⃣ Crear Keystore para Firma Digital

El keystore es necesario para firmar tu aplicación de manera segura.

### Paso 2.1: Generar el Keystore

Abre PowerShell y ejecuta:

```powershell
cd android\app
keytool -genkey -v -keystore amigazos-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias amigazos
```

**Te pedirá:**
- Password del keystore (¡GUÁRDALO EN LUGAR SEGURO!)
- Nombre, organización, ciudad, país
- Password del alias (puede ser el mismo que el keystore)

**⚠️ CRÍTICO:** 
- Guarda el archivo `.jks` en un lugar seguro (NO lo subas a Git)
- Guarda las contraseñas en un gestor de contraseñas
- Si pierdes el keystore, NO podrás actualizar tu app en Google Play

### Paso 2.2: Mover el Keystore
Mueve el archivo `amigazos-release-key.jks` a una ubicación segura fuera del proyecto, por ejemplo:
```
C:\Users\TuUsuario\keystores\amigazos-release-key.jks
```

---

## 3️⃣ Configurar Firma de la Aplicación

### Paso 3.1: Crear archivo key.properties

Crea el archivo `android/key.properties` con el siguiente contenido:

```properties
storePassword=TU_PASSWORD_DEL_KEYSTORE
keyPassword=TU_PASSWORD_DEL_ALIAS
keyAlias=amigazos
storeFile=C:\\Users\\TuUsuario\\keystores\\amigazos-release-key.jks
```

**⚠️ IMPORTANTE:** 
- Usa doble barra invertida `\\` en Windows para las rutas
- Este archivo NO debe subirse a Git (ya está en .gitignore)

### Paso 3.2: Verificar que key.properties está en .gitignore

Verifica que `android/.gitignore` contiene:
```
key.properties
*.jks
```

### Paso 3.3: Actualizar android/app/build.gradle.kts

Reemplaza la sección actual con:

```kotlin
// Antes de android {
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.mhc.amigazos"  // Actualiza con tu nuevo ID
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    // Configuración de firma
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    defaultConfig {
        applicationId = "com.mhc.amigazos"  // Actualiza aquí también
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // Habilitar ProGuard/R8 para optimización
            minifyEnabled = true
            shrinkResources = true
        }
    }
}
```

---

## 4️⃣ Actualizar Versión de la Aplicación

### En pubspec.yaml

```yaml
version: 1.0.0+1
```

**Formato:** `MAJOR.MINOR.PATCH+BUILD_NUMBER`
- Primera versión: `1.0.0+1`
- Segundo release: `1.0.0+2` (si es solo bug fix)
- Nueva funcionalidad: `1.1.0+3`

Para cada actualización:
- Incrementa el número después del `+` (build number)
- Actualiza la versión semántica según corresponda

---

## 5️⃣ Configurar Firebase para Producción

### Paso 5.1: Crear aplicación de producción en Firebase

1. Ve a [Firebase Console](https://console.firebase.google.com)
2. Selecciona tu proyecto
3. Agrega una nueva aplicación Android (si usas el mismo proyecto) o crea un proyecto nuevo
4. Usa el nuevo Application ID: `com.mhc.amigazos`
5. Descarga el nuevo `google-services.json`

### Paso 5.2: Actualizar google-services.json

Reemplaza `android/app/google-services.json` con el nuevo archivo descargado.

### Paso 5.3: Configurar servicios de Firebase

En Firebase Console, configura:
- ✅ Authentication (Google Sign-In, etc.)
- ✅ Firestore Database (reglas de producción)
- ✅ Cloud Messaging (notificaciones push)
- ✅ App Links / Dynamic Links

### Paso 5.4: Actualizar Reglas de Firestore

Revisa `firestore.rules` y asegúrate de que las reglas sean seguras para producción:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // NO usar allow read, write: if true; en producción
    match /{document=**} {
      allow read, write: if request.auth != null;  // Solo usuarios autenticados
    }
  }
}
```

---

## 6️⃣ Preparar la Aplicación

### Paso 6.1: Revisar permisos en AndroidManifest.xml

Verifica que solo tengas los permisos necesarios en `android/app/src/main/AndroidManifest.xml`.

### Paso 6.2: Configurar icono de la aplicación

Asegúrate de tener iconos de buena calidad en:
- `android/app/src/main/res/mipmap-*/ic_launcher.png`

Puedes generarlos en: https://romannurik.github.io/AndroidAssetStudio/

### Paso 6.3: Limpiar y verificar el proyecto

```powershell
flutter clean
flutter pub get
flutter analyze
flutter test
```

---

## 7️⃣ Generar App Bundle de Producción

### Paso 7.1: Construir el App Bundle

```powershell
flutter build appbundle --release
```

El archivo se generará en:
```
build\app\outputs\bundle\release\app-release.aab
```

### Paso 7.2: (Opcional) Generar APK

Si necesitas un APK para pruebas:
```powershell
flutter build apk --release
```

El APK estará en:
```
build\app\outputs\flutter-apk\app-release.apk
```

**⚠️ Nota:** Google Play Store requiere App Bundle (.aab), no APK para nuevas aplicaciones.

---

## 8️⃣ Preparar Assets para Google Play Store

Necesitarás:

### Screenshots
- Al menos 2 screenshots por tipo de dispositivo
- Tamaños: 16:9 o 9:16
- Formatos: PNG o JPEG

### Gráficos promocionales
- Icono de la aplicación: 512x512 PNG
- Gráfico de características: 1024x500 PNG
- (Opcional) Video promocional

### Textos
- Título de la app (máx. 50 caracteres): "Amigazos"
- Descripción corta (máx. 80 caracteres)
- Descripción completa (máx. 4000 caracteres)
- Política de privacidad (URL requerida)

---

## 9️⃣ Publicar en Google Play Store

### Paso 9.1: Crear cuenta de Google Play Console

1. Ve a [Google Play Console](https://play.google.com/console)
2. Paga la tarifa única de registro ($25 USD)
3. Completa la información de tu cuenta de desarrollador

### Paso 9.2: Crear nueva aplicación

1. Click en "Crear aplicación"
2. Ingresa el nombre: "Amigazos"
3. Selecciona idioma predeterminado
4. Tipo: Aplicación/Juego
5. Categoría: selecciona la apropiada

### Paso 9.3: Completar la ficha de Play Store

En Google Play Console, completa:

1. **Presencia en Play Store**
   - Título, descripción
   - Screenshots
   - Icono

2. **Configuración de la aplicación**
   - Política de privacidad
   - Categoría de la aplicación
   - Información de contacto

3. **Clasificación de contenido**
   - Completa el cuestionario de clasificación

4. **Países y regiones**
   - Selecciona dónde distribuir la app

5. **Precios**
   - Gratis o de pago

### Paso 9.4: Subir el App Bundle

1. Ve a "Producción" → "Crear nuevo lanzamiento"
2. Sube `app-release.aab`
3. Completa las notas de la versión
4. Revisa y publica

### Paso 9.5: Revisión de Google

- Google revisará tu app (puede tomar de horas a días)
- Recibirás un email cuando esté aprobada
- Una vez aprobada, estará disponible en Google Play Store

---

## 🔟 Post-Publicación

### Monitoreo
- Revisa los informes de crashs en Play Console
- Configura Firebase Crashlytics para reportes detallados
- Monitorea reviews y ratings

### Actualizaciones
Para publicar actualizaciones:
1. Incrementa el build number en `pubspec.yaml`
2. Realiza los cambios necesarios
3. Genera nuevo App Bundle
4. Sube a Play Console → Producción

---

## ✅ Checklist Final Antes de Publicar

- [ ] Application ID cambiado de `com.example.amigazos`
- [ ] Keystore creado y guardado de forma segura
- [ ] key.properties configurado correctamente
- [ ] Configuración de firma en build.gradle.kts actualizada
- [ ] google-services.json de producción configurado
- [ ] Reglas de Firestore seguras para producción
- [ ] Versión actualizada en pubspec.yaml
- [ ] Icono de la app de alta calidad
- [ ] Screenshots preparados
- [ ] Descripción y textos de Play Store listos
- [ ] Política de privacidad publicada (URL)
- [ ] App Bundle generado sin errores
- [ ] Probado en dispositivo físico
- [ ] Cuenta de Google Play Console creada
- [ ] Toda la información de la ficha de Play Store completa

---

## 🆘 Troubleshooting

### Error: "App not installed"
- Verifica que el Application ID sea único
- Desinstala versiones anteriores

### Error de firma
- Verifica las rutas en key.properties
- Verifica las contraseñas

### Google Play rechaza el App Bundle
- Verifica que targetSdkVersion sea reciente (33+)
- Revisa los requisitos de Google Play

### Crashs en producción
- Habilita Firebase Crashlytics
- Revisa los logs en Play Console

---

## 📚 Recursos Adicionales

- [Documentación oficial de Flutter - Deployment](https://docs.flutter.dev/deployment/android)
- [Google Play Console](https://play.google.com/console)
- [Firebase Console](https://console.firebase.google.com)
- [Política de Google Play](https://play.google.com/about/developer-content-policy/)

---

## 📝 Notas Importantes

1. **Backup del Keystore**: Haz múltiples copias del archivo .jks en lugares seguros
2. **Versiones**: Cada nueva versión debe tener un build number mayor
3. **Testing**: Prueba exhaustivamente antes de publicar
4. **Reglas de Firebase**: Nunca uses reglas permisivas en producción
5. **Application ID**: Una vez publicada, NO puedes cambiar el Application ID

---

**¡Buena suerte con el lanzamiento de Amigazos! 🚀**
