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
mkdir -p /home/templates
mkdir -p /home/videos
mkdir -p /home/midias_inativas
chmod -R 777 /home/templates
chmod -R 777 /home/videos
chmod -R 777 /home/midias_inativas

# Criando o arquivo mpv.conf
echo "Configurando mpv.conf..."
cat <<EOF > ~/.config/mpv/mpv.conf
hwdec=auto
vo=gpu
gpu-context=x11
EOF

# Movendo arquivos para os diretórios
echo "Movendo arquivos para os diretórios..."
curl -fsSL https://raw.githubusercontent.com/desenvolvimentogrupopixelpoint/pixel_play.1.0/main/Logo.png -o /home/Logo.png || { echo "Erro ao baixar Logo.png"; exit 1; }
curl -fsSL https://raw.githubusercontent.com/desenvolvimentogrupopixelpoint/pixel_play.1.0/main/templates/Index.html -o /home/templates/Index.html || { echo "Erro ao baixar Index.html"; exit 1; }
curl -fsSL https://raw.githubusercontent.com/desenvolvimentogrupopixelpoint/pixel_play.1.0/main/templates/logop.png -o /home/templates/logop.png || { echo "Erro ao baixar logop.png"; exit 1; }
echo "{}" > /home/metadata.json

# Criando o script de controle do HDMI
echo "Criando script de controle do HDMI..."
cat <<'EOF' > /root/control_hdmi.sh
#!/bin/bash

CONFIG_FILE="/boot/armbianEnv.txt"

# Adiciona um atraso de 30 segundos antes de executar qualquer ação
sleep 5 

if [[ "$1" == "off" ]]; then
    # Desligar HDMI
    sed -i 's/^#extraargs=video=HDMI-A-1:d/extraargs=video=HDMI-A-1:d/' "$CONFIG_FILE"
    echo "HDMI desligado às $(date)" >> /var/log/hdmi_control.log
elif [[ "$1" == "on" ]]; then
    # Ligar HDMI
    sed -i 's/^extraargs=video=HDMI-A-1:d/#extraargs=video=HDMI-A-1:d/' "$CONFIG_FILE"
    echo "HDMI ligado às $(date)" >> /var/log/hdmi_control.log
else
    echo "Uso: $0 [on|off]"
    exit 1
fi

# Reinicia o sistema para aplicar as mudanças
/sbin/reboot
EOF

sudo chmod +x /root/control_hdmi.sh

# Configurando visudo
echo "Configurando permissões do visudo..."
cat <<EOF | sudo tee -a /etc/sudoers
root ALL=(ALL) NOPASSWD: /sbin/reboot
EOF

# Configurando cron para desligar e ligar HDMI
echo "Configurando cron..."
(crontab -l 2>/dev/null; echo "30 22 * * * /root/control_hdmi.sh off") | crontab -
(crontab -l 2>/dev/null; echo "55 7 * * * /root/control_hdmi.sh on") | crontab -
sudo systemctl restart cron

# Criando o serviço hdmi_control
echo "Configurando serviço hdmi_control..."
cat <<EOF > /etc/systemd/system/hdmi_control.service
[Unit]
Description=HDMI Control Service
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash /root/control_hdmi.sh
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable hdmi_control.service
sudo systemctl start hdmi_control.service

# Configurando rc.local
echo "Configurando rc.local..."
cat <<EOF > /etc/rc.local
#!/bin/bash
(sleep 4 && fim -q -a /home/Logo.png) &
exit 0
EOF
chmod +x /etc/rc.local
sudo /etc/rc.local

# Configurando o serviço play_videos
echo "Configurando serviço play_videos..."
curl -fsSL https://raw.githubusercontent.com/desenvolvimentogrupopixelpoint/pixel_play.1.0/main/play_videos.service -o /etc/systemd/system/play_videos.service || { echo "Erro ao baixar play_videos.service"; exit 1; }
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
