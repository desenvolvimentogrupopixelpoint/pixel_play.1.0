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

# Instalando Flask
echo "Instalando Flask..."
sudo pip3 install flask werkzeug --break-system-packages || { echo "Erro ao instalar Flask. Finalizando a instalação."; exit 1; }

# Criando pastas e configurando permissões
echo "Criando pastas e configurando permissões..."
mkdir -p ~/.config/mpv
chmod -R 777 ~/.config/mpv
mkdir -p /home/videos
mkdir -p /home/midias_inativas
mkdir -p /home/pixelpoint/templates
chmod -R 777 /home/videos
chmod -R 777 /home/midias_inativas
chmod -R 777 /home/pixelpoint


# Movendo a pasta templates para pixelpoint
echo "Movendo a pasta templates para /home/pixelpoint..."
if [ -d "/home/templates" ]; then
    mv /home/templates /home/pixelpoint/templates || { echo "Erro ao mover a pasta templates"; exit 1; }
fi
chmod -R 777 /home/pixelpoint/templates

# Criando o arquivo mpv.conf
echo "Configurando mpv.conf..."
cat <<EOF > ~/.config/mpv/mpv.conf
hwdec=auto
vo=gpu
gpu-context=x11
EOF

# Movendo arquivos para os diretórios
echo "Baixando e movendo arquivos para os diretórios..."
curl -fsSL https://raw.githubusercontent.com/desenvolvimentogrupopixelpoint/pixel_play.1.0/main/Logo.png -o /home/Logo.png || { echo "Erro ao baixar Logo.png"; exit 1; }
curl -fsSL https://raw.githubusercontent.com/desenvolvimentogrupopixelpoint/pixel_play.1.0/main/templates/Index.html -o /home/pixelpoint/templates/Index.html || { echo "Erro ao baixar Index.html"; exit 1; }
curl -fsSL https://raw.githubusercontent.com/desenvolvimentogrupopixelpoint/pixel_play.1.0/main/templates/Logop.png -o /home/pixelpoint/templates/Logop.png || { echo "Erro ao baixar logop.png"; exit 1; }
curl -fsSL https://raw.githubusercontent.com/desenvolvimentogrupopixelpoint/pixel_play.1.0/main/play_videos.py -o /home/pixelpoint/play_videos.py || { echo "Erro ao baixar play_videos.py"; exit 1; }
echo "{}" > /home/metadata.json

# Definindo a Logo.png como papel de parede
echo "Definindo papel de parede..."
pcmanfm --set-wallpaper /home/Logo.png

# Configurando o serviço play_videos
echo "Configurando serviço play_videos..."
curl -fsSL https://raw.githubusercontent.com/desenvolvimentogrupopixelpoint/pixel_play.1.0/main/play_videos.service -o /etc/systemd/system/play_videos.service || { echo "Erro ao baixar play_videos.service"; exit 1; }
chmod 644 /etc/systemd/system/play_videos.service
sudo systemctl daemon-reload
sudo systemctl enable play_videos.service
sudo systemctl start play_videos.service

# Configurando desligamento automático às 22:25 via Crontab do root
echo "Configurando desligamento automático diário às 22:25..."
(sudo crontab -l 2>/dev/null; echo "25 22 * * * /sbin/shutdown -h now") | sudo crontab -

# Finalizando
echo "Instalação concluída com sucesso!"
sudo timedatectl set-timezone America/Sao_Paulo


# Instalando e configurando Tailscale
echo "Instalando e configurando Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh
sudo systemctl enable tailscaled
sudo systemctl start tailscaled

# Finalizando
echo "Instalação concluída com sucesso!"
sudo timedatectl set-timezone America/Sao_Paulo

# Conexão com Tailscale
echo "Conectando ao Tailscale..."
sudo tailscale up
