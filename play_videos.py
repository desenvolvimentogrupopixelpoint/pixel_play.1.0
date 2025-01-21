import os
import subprocess
from flask import Flask, request, jsonify, render_template, send_from_directory
from werkzeug.utils import secure_filename
from threading import Thread
from datetime import datetime
import json
import time

UPLOAD_FOLDER = '/home/pixelpoint/videos'
INACTIVE_FOLDER = '/home/pixelpoint/midias_inativas'
ALLOWED_EXTENSIONS = {'mp4'}
METADATA_FILE = '/home/pixelpoint/metadata.json'

app = Flask(__name__, template_folder='/home/pixelpoint/templates')
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

# Ensure both folders exist
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(INACTIVE_FOLDER, exist_ok=True)


def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def load_metadata():
    if os.path.exists(METADATA_FILE):
        with open(METADATA_FILE, 'r') as f:
            return json.load(f)
    return {}

def save_metadata(metadata):
    with open(METADATA_FILE, 'w') as f:
        json.dump(metadata, f)

def move_to_inactive(filename):
    source_path = os.path.join(UPLOAD_FOLDER, filename)
    target_path = os.path.join(INACTIVE_FOLDER, filename)
    if os.path.exists(source_path):
        os.rename(source_path, target_path)

def move_to_active(filename):
    source_path = os.path.join(INACTIVE_FOLDER, filename)
    target_path = os.path.join(UPLOAD_FOLDER, filename)
    if os.path.exists(source_path):
        os.rename(source_path, target_path)


def play_all_videos_in_loop():
    while True:
        files_in_active = sorted(
            [f for f in os.listdir(UPLOAD_FOLDER) if f.lower().endswith('.mp4')]
        )

        if files_in_active:
            for file in files_in_active:
                video_path = os.path.join(UPLOAD_FOLDER, file)
                subprocess.Popen([
                    "mpv", "--fs", "--no-audio", "--quiet", "--gapless-audio", video_path
], stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL).wait()
        else:
            time.sleep(1)  # Wait if the folder is empty


def monitor_media():
    while True:
        now = datetime.now()
        metadata = load_metadata()
        metadata = load_metadata()
        files_in_active = os.listdir(UPLOAD_FOLDER)

        for filename, details in metadata.items():
            start_time = datetime.fromisoformat(details['start_time']) if details['start_time'] else None
            end_time = datetime.fromisoformat(details['end_time']) if details['end_time'] else None

            if start_time and now >= start_time:
                if os.path.exists(os.path.join(INACTIVE_FOLDER, filename)):
                    move_to_active(filename)

            if end_time and now > end_time:
                if os.path.exists(os.path.join(UPLOAD_FOLDER, filename)):
                    move_to_inactive(filename)

        time.sleep(1)  # Check every second


@app.route('/templates/<path:filename>')
def serve_static(filename):
    return send_from_directory('/home/pixelpoint/templates', filename)


@app.route('/')
def index():
    return render_template('index.html')

@app.route('/list', methods=['GET'])
def list_files():
    metadata = load_metadata()
    active_files = []
    inactive_files = []

    for folder, file_list in [(UPLOAD_FOLDER, active_files), (INACTIVE_FOLDER, inactive_files)]:
        for file in os.listdir(folder):
            if file.lower().endswith('.mp4'):
                file_path = os.path.join(folder, file)
                size = round(os.path.getsize(file_path) / (1024 * 1024), 2)
                file_metadata = metadata.get(file, {})
                start_time = file_metadata.get('start_time', '-')
                end_time = file_metadata.get('end_time', '-')

                file_list.append({
                    'name': file,
                    'size': size,
                    'start_time': start_time,
                    'end_time': end_time
                })

    return jsonify({'active': active_files, 'inactive': inactive_files})

@app.route('/upload', methods=['POST'])
def upload_file():
    metadata = load_metadata()
    if 'file' not in request.files:
        return jsonify({'status': 'error', 'message': 'Nenhum arquivo enviado.'}), 400

    file = request.files['file']

    if file.filename == '':
        return jsonify({'status': 'error', 'message': 'Nenhum arquivo selecionado.'}), 400

    if file and allowed_file(file.filename):
        filename = secure_filename(file.filename)
        try:
            start_time = request.form.get('start_time')
            end_time = request.form.get('end_time')

            if start_time and datetime.fromisoformat(start_time) > datetime.now():
                save_path = os.path.join(INACTIVE_FOLDER, filename)
            else:
                save_path = os.path.join(UPLOAD_FOLDER, filename)

            file.save(save_path)
            metadata[filename] = {'start_time': start_time, 'end_time': end_time}
            save_metadata(metadata)

            return jsonify({'status': 'success', 'message': f"Arquivo {filename} carregado com sucesso!"}), 200
        except Exception as e:
            return jsonify({'status': 'error', 'message': f"Erro ao salvar o arquivo: {str(e)}"}), 500
    else:
        return jsonify({'status': 'error', 'message': 'Formato de arquivo inválido. Apenas .mp4 é permitido.'}), 400

@app.route('/delete', methods=['POST'])
def delete_file():
    filename = request.json.get('filename')  # Nome do arquivo a ser excluído
    folder = request.json.get('folder')  # Pasta (active ou inactive)

    # Verifica se os parâmetros necessários foram enviados
    if not filename:
        return jsonify({'status': 'error', 'message': 'Nenhum arquivo especificado.'}), 400
    if not folder:
        return jsonify({'status': 'error', 'message': 'Pasta não especificada.'}), 400

    # Define o caminho da pasta com base no parâmetro "folder"
    if folder == 'active':
        folder_path = UPLOAD_FOLDER
    elif folder == 'inactive':
        folder_path = INACTIVE_FOLDER
    else:
        return jsonify({'status': 'error', 'message': 'Pasta desconhecida especificada.'}), 400

    # Cria o caminho completo para o arquivo
    file_path = os.path.join(folder_path, filename)

    print(f"Tentando excluir o arquivo: {file_path}")  # Log para depuração

    # Verifica se o arquivo existe e tenta excluí-lo
    if os.path.exists(file_path):
        try:
            os.remove(file_path)  # Remove o arquivo
            metadata = load_metadata()  # Carrega o metadata.json
            if filename in metadata:
                del metadata[filename]  # Remove o registro do arquivo no metadata.json
            save_metadata(metadata)  # Salva o metadata atualizado
            return jsonify({'status': 'success', 'message': f"Arquivo {filename} excluído com sucesso."}), 200
        except Exception as e:
            return jsonify({'status': 'error', 'message': f"Erro ao excluir o arquivo: {str(e)}"}), 500
    else:
        return jsonify({'status': 'error', 'message': f"Arquivo {filename} não encontrado na pasta {folder}."}), 404


if __name__ == "__main__":
    try:
        monitor_thread = Thread(target=monitor_media, daemon=True)
        monitor_thread.start()

        play_thread = Thread(target=play_all_videos_in_loop, daemon=True)
        play_thread.start()

        app.run(debug=False, host="0.0.0.0", port=5000)  # Debug desativado para leveza
    except KeyboardInterrupt:
        pass

