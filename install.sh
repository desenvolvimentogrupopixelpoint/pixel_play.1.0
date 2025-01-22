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
sudo systemctl daemon-reload
sudo systemctl enable play_videos.service
sudo systemctl start play_videos.service

# Adicionando configuração HDMI
echo "Configurando controle HDMI..."
cat <<EOF > /root/control_hdmi.sh
#!/bin/bash

CONFIG_FILE="/boot/armbianEnv.txt"

# Adiciona um atraso de 15 segundos antes de executar qualquer ação
sleep 15

if [[ "\$1" == "off" ]]; then
    # Desligar HDMI
    sed -i 's/^#extraargs=video=HDMI-A-1:d/extraargs=video=HDMI-A-1:d/' "\$CONFIG_FILE"
    echo "HDMI desligado às \$(date)" >> /var/log/hdmi_control.log
elif [[ "\$1" == "on" ]]; then
    # Ligar HDMI
    sed -i 's/^extraargs=video=HDMI-A-1:d/#extraargs=video=HDMI-A-1:d/' "\$CONFIG_FILE"
    echo "HDMI ligado às \$(date)" >> /var/log/hdmi_control.log
else
    echo "Uso: \$0 [on|off]"
    exit 1
fi

# Reinicia o sistema para aplicar as mudanças
/sbin/reboot
EOF

chmod +x /root/control_hdmi.sh

# Sistema para adicionar linha ao final do arquivo
cat <<EOF > /root/add_hdmi_config.sh
#!/bin/bash

CONFIG_FILE="/boot/armbianEnv.txt"

# Verifica se a linha já existe, caso contrário, adiciona ao final do arquivo
if ! grep -q "^extraargs=video=HDMI-A-1:d" "\$CONFIG_FILE"; then
    echo "Adicionando linha 'extraargs=video=HDMI-A-1:d' ao final do arquivo."
    echo "extraargs=video=HDMI-A-1:d" >> "\$CONFIG_FILE"
    echo "Linha adicionada com sucesso em \$(date)" >> /var/log/hdmi_addition.log
else
    echo "Linha 'extraargs=video=HDMI-A-1:d' já existe. Nenhuma ação realizada."
    echo "Linha já existente em \$(date)" >> /var/log/hdmi_addition.log
fi
EOF

chmod +x /root/add_hdmi_config.sh

# Configurando agendador HDMI
cat <<EOF > /root/hdmi_scheduler.py
import os
from datetime import datetime
import time

def execute_hdmi_command(command):
    if command == "on":
        result = os.system("sudo /root/control_hdmi.sh on")
        print(f"[{datetime.now()}] HDMI ligado. Resultado do comando: {result}")
    elif command == "off":
        result = os.system("sudo /root/control_hdmi.sh off")
        print(f"[{datetime.now()}] HDMI desligado. Resultado do comando: {result}")

# Configurar horários
HDMI_OFF_TIME = "22:30"  # Horário para DESLIGAR
HDMI_ON_TIME = "7:55"   # Horário para LIGAR

print("Agendador HDMI iniciado. Aguardando horários programados...")

try:
    while True:
        current_time = datetime.now().strftime("%H:%M")
        print(f"[{datetime.now()}] Verificando horário: {current_time}")

        if current_time == HDMI_OFF_TIME:
            print(f"[{current_time}] Desligando HDMI...")
            execute_hdmi_command("off")
            time.sleep(60)  # Aguarda 1 minuto para evitar execução repetida

        elif current_time == HDMI_ON_TIME:
            print(f"[{current_time}] Ligando HDMI...")
            execute_hdmi_command("on")
            time.sleep(60)  # Aguarda 1 minuto para evitar execução repetida

        time.sleep(1)  # Checa o horário a cada segundo

except KeyboardInterrupt:
    print("\nPrograma encerrado pelo usuário.")
EOF

chmod +x /root/hdmi_scheduler.py

cat <<EOF > /etc/systemd/system/hdmi_scheduler.service
[Unit]
Description=Agendador HDMI
After=network.target

[Service]
ExecStart=/usr/bin/python3 /root/hdmi_scheduler.py
WorkingDirectory=/root
StandardOutput=append:/var/log/hdmi_scheduler.log
StandardError=append:/var/log/hdmi_scheduler_error.log
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable hdmi_scheduler.service
sudo systemctl start hdmi_scheduler.service

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
