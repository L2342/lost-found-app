# Encuéntralo — Lost & Found App

## Setup inicial (hacer una sola vez)

```bash
git clone [URL_DEL_REPO]
git checkout [TU_NOMBRE]   # daniela | jarol | david
flutter pub get
```

## Comandos diarios

```bash
# Al empezar — traer lo nuevo de Samuel
git pull origin main

# Al terminar algo que funciona
git add .
git commit -m "US-XX: descripción corta"
git push origin [TU_NOMBRE]
```

## Regla de oro
**Nunca hagas push a main.** Solo Samuel hace merge.

---

## Estructura del proyecto

```
lib/
  main.dart
  models/
    user_model.dart       ← modelo de usuario
    report_model.dart     ← modelo de reporte
  services/
    auth_service.dart     ← Daniela usa esto
    report_service.dart   ← Jarol y David usan esto
    user_service.dart     ← David y Daniela usan esto
    cloudinary_service.dart ← Jarol usa esto para imágenes
  screens/
    [cada dev crea sus pantallas aquí]
```

## Stack

| Capa | Tecnología |
|---|---|
| Frontend | Flutter / Dart |
| Auth + BD | Firebase Auth + Firestore |
| Imágenes | Cloudinary (NO Firebase Storage) |
| Admin backend | Python Flask |

## Responsabilidades

| Dev | US obligatorias |
|---|---|
| Daniela | US-05 registro, US-06 login, US-22 logout |
| Jarol | US-08 reportar perdido, US-09 reportar encontrado, US-10 editar |
| David | US-12 feed, US-13 detalle, US-16 contactar |
| Samuel | Firebase + servicios + arquitectura + docs Scrum |

## Notas importantes

- Las imágenes se suben a **Cloudinary**, no a Firebase Storage.
- `CloudinaryService.uploadImage(file)` retorna una URL String que se guarda en Firestore.
- Para contactar por WhatsApp: `launchUrl(Uri.parse('https://wa.me/57${phone}'))`
- Los filtros de búsqueda (US-14, US-15) se hacen en cliente, no en Firestore.
