# Configuración de App Links (Android) y Universal Links (iOS) para Reset de Contraseña

### Documentación oficial de Flutter:
https://docs.flutter.dev/install/quick

## ✅ Archivos creados automáticamente:

### Android App Links:
- `public/.well-known/assetlinks.json` ✅

### iOS Universal Links:
- `public/.well-known/apple-app-site-association` ✅

## 🔧 PASOS PENDIENTES:

### 1. Actualizar Apple Team ID en iOS

Edita el archivo `public/.well-known/apple-app-site-association`:

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TU_TEAM_ID_AQUI.com.example.amigazos",
        "paths": ["/reset-password*"]
      }
    ]
  }
}
```

**¿Dónde encontrar tu Apple Team ID?**
- Ve a [developer.apple.com/account](https://developer.apple.com/account)
- En "Membership" → "Team ID"
- Copia el valor (ej: `ABC123DEF4`)

### 2. Deploy a Firebase Hosting

```bash
firebase deploy --only hosting
```

### 3. Verificar que los archivos estén accesibles:

- Android: `https://amigazos-db.web.app/.well-known/assetlinks.json`
- iOS: `https://amigazos-db.web.app/.well-known/apple-app-site-association`

### 4. Actualizar Firebase Auth Email Template

En Firebase Console:
1. **Authentication** → **Templates** → **Password reset**
2. Cambia la URL por: `https://amigazos-db.web.app/`  ///https://amigazos-db.web.app/reset-password
3. Guarda

## ⚠️ Notas importantes:

- Los cambios pueden tardar 24-48 horas en propagarse
- Para testing, funciona mejor en dispositivos reales que en emuladores
- Si usas un keystore de producción diferente, necesitarás actualizar el SHA256 en `assetlinks.json`