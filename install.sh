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
sudo apt install -y mpv fim python3 python3-pip python3-venv python3-dev \
    libdrm-dev libx11-dev libva-dev libvdpau-dev libxcb-shm0-dev libxext-dev libxcb1-dev libasound2-dev \
    mesa-va-drivers mesa-vdpau-drivers vdpauinfo vainfo

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

