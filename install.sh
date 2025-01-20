#!/bin/bash

set -e

# Definindo o caminho base do GitHub
BASE_URL="https://raw.githubusercontent.com/desenvolvimentogrupopixelpoint/pixel_play.1.0/main"

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

# Movendo arquivos para os diretórios apropriados
echo "Baixando e movendo arquivos para os diretórios..."
curl -fsSL "$BASE_URL/Logo.png" -o /home/pixelpoint/Logo.png || { echo "Erro ao baixar Logo.png"; exit 1; }
curl -fsSL "$BASE_URL/templates/index.html" -o /home/pixelpoint/templates/index.html || { echo "Erro ao baixar index.html"; exit 1; }
curl -fsSL "$BASE_URL/templates/logop.png" -o /home/pixelpoint/templates/logop.png || { echo "Erro ao baixar logop.png"; exit 1; }
curl -fsSL "$BASE_URL/control_hdmi.sh" -o /root/control_hdmi.sh || { echo "Erro ao baixar control_hdmi.sh"; exit 1; }
chmod +x /root/control_hdmi.sh
curl -fsSL "$BASE_URL/metadata.json" -o /home/pixelpoint/metadata.json || { echo "Erro ao baixar metadata.json"; exit 1; }

# Configurando cron para desligar e ligar HDMI
echo "Configurando cron..."
(crontab -l 2>/dev/null; echo "30 22 * * * /root/control_hdmi.sh off") | crontab -
(crontab -l 2>/dev/null; echo "55 7 * * * /root/control_hdmi.sh on") | crontab -
sudo systemctl restart cron

# Configurando o serviço hdmi_control
echo "Configurando serviço hdmi_control..."
curl -fsSL "$BASE_URL/control_hdmi.service" -o /etc/systemd/system/hdmi_control.service || { echo "Erro ao baixar hdmi_control.service"; exit 1; }
sudo systemctl enable hdmi_control.service
sudo systemctl start hdmi_control.service

# Configurando rc.local
echo "Configurando rc.local..."
cat <<EOF > /etc/rc.local
#!/bin/bash
(sleep 4 && fim -q -a /home/pixelpoint/Logo.png) &
exit 0
EOF
chmod +x /etc/rc.local
sudo /etc/rc.local

# Configurando o serviço play_videos
echo "Configurando serviço play_videos..."
curl -fsSL "$BASE_URL/play_videos.service" -o /etc/systemd/system/play_videos.service || { echo "Erro ao baixar play_videos.service"; exit 1; }
chmod 644 /etc/systemd/system/play_videos.service
sudo systemctl enable play_videos.service
sudo systemctl start play_videos.service

# Instalando e configurando Tailscale
echo "Instalando e configurando Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh
sudo systemctl enable tailscaled
sudo systemctl start tailscaled
sudo tailscale status

# Finalizando
echo "Instalação concluída com sucesso!"
