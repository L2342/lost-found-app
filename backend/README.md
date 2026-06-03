# Encuéntralo — Backend Flask

## Setup (hazlo una sola vez)

### 1. Crear entorno virtual
```bash
cd backend
python -m venv venv
venv\Scripts\activate       # Windows
```

### 2. Instalar dependencias
```bash
pip install -r requirements.txt
```

### 3. Descargar serviceAccountKey.json
- Firebase Console → Configuración del proyecto ⚙️
- Pestaña: Cuentas de servicio
- Botón: Generar nueva clave privada
- Guardar el archivo como `serviceAccountKey.json` en esta carpeta
- ⚠️ NUNCA subir este archivo al repo (está en .gitignore)

### 4. Obtener API key de Gemini (gratis)
- Ir a: https://aistudio.google.com/app/apikey
- Crear API key
- Copiar `.env.example` a `.env` y completar:
```
GEMINI_API_KEY=tu_api_key_aqui
ADMIN_TOKEN=admin-token-encuentralo
```

### 5. Correr el servidor
```bash
python app.py
```
Servidor corre en: http://localhost:5000

## Endpoints

| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | /api/admin/estadisticas | Métricas del sistema (US-20) |
| GET | /api/admin/usuarios | Listar usuarios (US-19) |
| DELETE | /api/admin/usuarios/:uid | Eliminar usuario |
| DELETE | /api/admin/reportes/:id | Eliminar reporte |
| POST | /ia/validar-imagen | Validar imagen con Gemini (US-19) |

## Header requerido para endpoints admin
```
Authorization: Bearer admin-token-encuentralo
```

## Nota para el frontend
- El frontend usa por defecto el mismo token: `admin-token-encuentralo`.
- Si cambias `ADMIN_TOKEN` en backend, debes ejecutar Flutter con:
```bash
flutter run -d chrome --dart-define=ADMIN_TOKEN=tu_token
```

## URL que David usa desde Flutter
```
http://localhost:5000/api/admin/estadisticas
http://localhost:5000/api/admin/usuarios
```
