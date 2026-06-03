from flask import Flask, request, jsonify
from flask_cors import CORS
import firebase_admin
from firebase_admin import credentials, firestore
from google import genai
from google.genai import types  # Importación necesaria para enviar las imágenes correctamente
import base64, os, json
from functools import wraps
from dotenv import load_dotenv


load_dotenv()

app = Flask(__name__)
CORS(app)

# ─── Firebase Admin SDK ───────────────────────────────────────────────────────
cred = credentials.Certificate('serviceAccountKey.json')
firebase_admin.initialize_app(cred)
db = firestore.client()

# ─── Gemini API (CORREGIDO) ───────────────────────────────────────────────────
GEMINI_API_KEY = os.environ.get('GEMINI_API_KEY')

# Si usas os.environ.get, debes pasar la key explícitamente con el parámetro 'api_key'
client = genai.Client(api_key=GEMINI_API_KEY)

# ─── Token admin simple ───────────────────────────────────────────────────────
ADMIN_TOKEN = (os.environ.get('ADMIN_TOKEN') or 'admin-token-encuentralo').strip()

def require_admin(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        auth_header = request.headers.get('Authorization', '').strip()
        token = auth_header[7:].strip() if auth_header.lower().startswith('bearer ') else auth_header
        if token != ADMIN_TOKEN:
            return jsonify({'success': False, 'message': 'Acceso no autorizado'}), 401
        return f(*args, **kwargs)
    return decorated

# ─── Health check ─────────────────────────────────────────────────────────────
@app.route('/')
def health():
    return jsonify({'status': 'ok', 'app': 'Encuentralo API'})

# ─── US-20: Estadisticas ──────────────────────────────────────────────────────
@app.route('/api/admin/estadisticas', methods=['GET'])
@require_admin
def get_estadisticas():
    try:
        total_usuarios   = len(db.collection('usuarios').get())
        total_reportes   = len(db.collection('reportes').get())
        total_perdidos   = len(db.collection('reportes').where('tipo',   '==', 'perdido').get())
        total_encontrados= len(db.collection('reportes').where('tipo',   '==', 'encontrado').get())
        total_recuperados= len(db.collection('reportes').where('estado', '==', 'recuperado').get())

        return jsonify({
            'success': True,
            'data': {
                'usuarios':    total_usuarios,
                'reportes':    total_reportes,
                'perdidos':    total_perdidos,
                'encontrados': total_encontrados,
                'recuperados': total_recuperados,
            }
        })
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 400

# ─── US-19: Listar usuarios ───────────────────────────────────────────────────
@app.route('/api/admin/usuarios', methods=['GET'])
@require_admin
def get_usuarios():
    try:
        docs = db.collection('usuarios').get()
        usuarios = [{
            'uid':   d.id,
            'name':  d.to_dict().get('name', ''),
            'email': d.to_dict().get('email', ''),
            'role':  d.to_dict().get('role', 'user'),
        } for d in docs]
        return jsonify({'success': True, 'data': {'total': len(usuarios), 'usuarios': usuarios}})
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 400

# ─── Eliminar usuario ─────────────────────────────────────────────────────────
@app.route('/api/admin/usuarios/<uid>', methods=['DELETE'])
@require_admin
def delete_usuario(uid):
    try:
        db.collection('usuarios').document(uid).delete()
        return jsonify({'success': True, 'message': 'Usuario eliminado correctamente'})
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 400

# ─── Eliminar reporte ─────────────────────────────────────────────────────────
@app.route('/api/admin/reportes/<report_id>', methods=['DELETE'])
@require_admin
def delete_reporte(report_id):
    try:
        db.collection('reportes').document(report_id).delete()
        return jsonify({'success': True, 'message': 'Reporte eliminado correctamente'})
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 400

# ─── US-19: Validar imagen con Gemini (CORREGIDO) ─────────────────────────────
@app.route('/ia/validar-imagen', methods=['POST'])
def validar_imagen():
    try:
        if 'imagen' in request.files:
            file = request.files['imagen']
            image_bytes = file.read()
            mime_type   = file.content_type or 'image/jpeg'
        elif request.is_json and 'imagen_base64' in request.json:
            image_bytes = base64.b64decode(request.json['imagen_base64'])
            mime_type   = request.json.get('mime_type', 'image/jpeg')
        else:
            return jsonify({'valida': False, 'mensaje': 'No se recibio ninguna imagen'}), 400

        prompt = """Analiza esta imagen para una app de objetos perdidos universitaria.
VALIDA si muestra un objeto fisico claro (llaves, celular, mochila, ropa, documentos, etc).
NO VALIDA si muestra personas, contenido inapropiado, pantalla en blanco o captura de pantalla."""

        # Estructura correcta para enviar imágenes usando la SDK moderna (types.Part.from_bytes)
        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=[
                prompt,
                types.Part.from_bytes(data=image_bytes, mime_type=mime_type)
            ],
            # Forzamos a Gemini a responder estrictamente en formato JSON válido estructurado
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=types.Schema(
                    type=types.Type.OBJECT,
                    properties={
                        "valida": types.Schema(type=types.Type.BOOLEAN),
                        "razon": types.Schema(type=types.Type.STRING),
                    },
                    required=["valida", "razon"]
                ),
            ),
        )

        # Como forzamos el esquema JSON, el parseo es directo y seguro
        result = json.loads(response.text)
        return jsonify({'valida': result.get('valida', False), 'mensaje': result.get('razon', '')})

    except Exception as e:
        # Imprime el error real en tu consola para depurar fallos de credenciales o de Firebase
        print(f"Error en validación IA: {e}")
        return jsonify({'valida': False, 'mensaje': f'Error en el servidor: {str(e)}'}), 500

if __name__ == '__main__':
    app.run(debug=True, port=5000)
