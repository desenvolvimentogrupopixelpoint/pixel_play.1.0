#!/bin/bash

set -e

# Definindo o caminho base como o diretório onde o script está
BASE_DIR=$(dirname "$(readlink -f "$0")")

# Atualização do sistema
echo "Atualizando o sistema..."
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y
sudo apt clean

# Instalando pacotes necessários
echo "Instalando pacotes necessários..."
sudo apt install -y mpv fim python3 python3-pip python3-venv python3-dev libdrm-dev libx11-dev libva-dev libvdpau-dev libxcb-shm0-dev libxext-dev libxcb1-dev libasound2-dev mesa-va-drivers mesa-vdpau-drivers vdpauinfo vainfo

# Criando pastas e configurando permissões
echo "Criando pastas e configurando permissões..."
mkdir -p ~/.config/mpv
chmod -R 777 ~/.config/mpv
mkdir -p /home/pixelpoint/templates
mkdir -p /home/pixelpoint/videos
mkdir -p /home/pixelpoint/midias_inativas
chmod -R 777 /home
chmod -R 777 /home/pixelpoint
chmod -R 777 /home/pixelpoint/templates
chmod -R 777 /home/pixelpoint/videos
chmod -R 777 /home/pixelpoint/midias_inativas

# Criando o arquivo mpv.conf
echo "Configurando mpv.conf..."
cat <<EOF > ~/.config/mpv/mpv.conf
hwdec=auto
vo=gpu
gpu-context=x11
EOF

# Movendo arquivos para os diretórios
echo "Movendo arquivos para os diretórios..."
cp "$BASE_DIR/Logo.png" /home/pixelpoint/ || { echo "Erro ao mover Logo.png"; exit 1; }
cp "$BASE_DIR/templates/Index.html" /home/pixelpoint/templates/ || { echo "Erro ao mover Index.html"; exit 1; }
cp "$BASE_DIR/templates/logop.png" /home/pixelpoint/templates/ || { echo "Erro ao mover logop.png"; exit 1; }
cp "$BASE_DIR/play_videos.py" /home/pixelpoint/ || { echo "Erro ao mover play_videos.py"; exit 1; }
echo "{}" > /home/pixelpoint/metadata.json

# Configurando o serviço play_videos
echo "Configurando serviço play_videos..."
cp "$BASE_DIR/play_videos.service" /etc/systemd/system/play_videos.service || { echo "Erro ao mover play_videos.service"; exit 1; }
chmod 644 /etc/systemd/system/play_videos.service
sudo systemctl daemon-reload
sudo systemctl enable play_videos.service
sudo systemctl start play_videos.service

# Instalando e configurando Tailscale
echo "Instalando e configurando Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh
sudo systemctl enable tailscaled
sudo systemctl start tailscaled

# Configurando Tailscale para iniciar
echo "Configurando Tailscale..."
sudo tailscale up || { echo "Erro ao conectar Tailscale. Verifique as credenciais ou configuração."; exit 1; }

# Finalizando
echo "Instalação concluída com sucesso!"
