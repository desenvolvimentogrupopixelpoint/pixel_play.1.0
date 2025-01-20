#!/bin/bash

set -e

# Definindo o caminho base do GitHub
BASE_URL="https://raw.githubusercontent.com/desenvolvimentogrupopixelpoint/pixel_play.1.0/main"

# Função para verificar e relatar erros
function check_status {
    if [ $? -ne 0 ]; then
        echo "Erro na etapa: $1"
        exit 1
    fi
}

# Atualização do sistema
echo "Atualizando o sistema..."
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && sudo apt clean
check_status "Atualização do sistema"

# Instalando pacotes necessários
echo "Instalando pacotes necessários..."
sudo apt install -y mpv fim python3 python3-pip python3-venv python3-dev \
    libdrm-dev libx11-dev libva-dev libvdpau-dev libxcb-shm0-dev libxext-dev \
    libxcb1-dev libasound2-dev mesa-va-drivers mesa-vdpau-drivers vdpauinfo vainfo
check_status "Instalação de pacotes"

# Criando pastas e configurando permissões
echo "Criando pastas e configurando permissões..."
mkdir -p ~/.config/mpv /home/pixelpoint/templates /home/pixelpoint/videos /home/pixelpoint/midias_inativas
chmod -R 777 ~/.config/mpv /home /home/pixelpoint /home/pixelpoint/templates /home/pixelpoint/videos /home/pixelpoint/midias_inativas
check_status "Criação de pastas e permissões"

# Criando o arquivo mpv.conf
echo "Configurando mpv.conf..."
cat <<EOF > ~/.config/mpv/mpv.conf
hwdec=auto
vo=gpu
gpu-context=x11
EOF
check_status "Configuração do mpv.conf"

# Movendo arquivos para os diretórios apropriados
echo "Baixando e movendo arquivos para os diretórios..."
curl -fsSL "$BASE_URL/Logo.png" -o /home/Logo.png
check_status "Baixar Logo.png"

curl -fsSL "$BASE_URL/templates/Index.html" -o /home/pixelpoint/templates/Index.html
check_status "Baixar Index.html"

curl -fsSL "$BASE_URL/templates/logop.png" -o /home/pixelpoint/templates/logop.png
check_status "Baixar logop.png"

curl -fsSL "$BASE_URL/control_hdmi.sh" -o /root/control_hdmi.sh
chmod +x /root/control_hdmi.sh
check_status "Baixar control_hdmi.sh"

curl -fsSL "$BASE_URL/metadata.json" -o /home/pixelpoint/metadata.json
check_status "Baixar metadata.json"

# Configurando cron para desligar e ligar HDMI
echo "Configurando cron..."
(crontab -l 2>/dev/null; echo "30 22 * * * /root/control_hdmi.sh off") | crontab -
(crontab -l 2>/dev/null; echo "55 7 * * * /root/control_hdmi.sh on") | crontab -
sudo systemctl restart cron
check_status "Configuração do cron"

# Configurando o serviço hdmi_control
echo "Configurando serviço hdmi_control..."
curl -fsSL "$BASE_URL/control_hdmi.service" -o /etc/systemd/system/hdmi_control.service
sudo systemctl enable hdmi_control.service
sudo systemctl start hdmi_control.service
check_status "Configuração do serviço hdmi_control"

# Configurando rc.local
echo "Configurando rc.local..."
cat <<EOF > /etc/rc.local
#!/bin/bash
(sleep 4 && fim -q -a /home/pixelpoint/Logo.png) &
exit 0
EOF
chmod +x /etc/rc.local
sudo /etc/rc.local
check_status "Configuração do rc.local"

# Configurando o serviço play_videos
echo "Configurando serviço play_videos..."
curl -fsSL "$BASE_URL/play_videos.service" -o /etc/systemd/system/play_videos.service
chmod 644 /etc/systemd/system/play_videos.service
sudo systemctl enable play_videos.service
sudo systemctl start play_videos.service
check_status "Configuração do serviço play_videos"

# Instalando e configurando Tailscale
echo "Instalando e configurando Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh
sudo systemctl enable tailscaled
sudo systemctl start tailscaled
sudo tailscale status
check_status "Instalação e configuração do Tailscale"

# Finalizando
echo "Instalação concluída com sucesso!"
