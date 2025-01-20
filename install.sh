#!/bin/bash

# Atualização do sistema
echo "Atualizando o sistema..."
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y
sudo apt clean

# Verificando se o sistema está ativo
echo "Verificando o status do sistema..."
sudo systemctl status ssh | grep -E "enabled|active"

# Instalando pacotes necessários
echo "Instalando pacotes necessários..."
sudo apt install -y mpv
sudo apt install -y fim
sudo apt install -y python3 python3-pip python3-venv python3-dev
sudo apt install -y libdrm-dev libx11-dev libva-dev libvdpau-dev libxcb-shm0-dev libxext-dev libxcb1-dev libasound2-dev
sudo apt install -y mesa-va-drivers mesa-vdpau-drivers
sudo apt install -y vdpauinfo vainfo

# Criando pastas e ajustando permissões
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
echo "Movendo arquivos para os diretórios..."
cp ./Logo.png /home/pixelpoint/
cp ./templates/index.html /home/pixelpoint/templates/
cp ./templates/logop.png /home/pixelpoint/templates/
cp ./control_hdmi.sh /root/control_hdmi.sh
chmod +x /root/control_hdmi.sh
echo "{}" > /home/pixelpoint/metadata.json

# Configurando cron para desligar e ligar HDMI
echo "Configurando cron..."
(crontab -l 2>/dev/null; echo "30 22 * * * /root/control_hdmi.sh off") | crontab -
(crontab -l 2>/dev/null; echo "55 7 * * * /root/control_hdmi.sh on") | crontab -
sudo systemctl restart cron

# Configurando o serviço hdmi_control
echo "Configurando serviço hdmi_control..."
cat <<EOF > /etc/systemd/system/hdmi_control.service
[Unit]
Description=HDMI Control Service
After=network.target

[Service]
Type=oneshot
ExecStart=/root/control_hdmi.sh on
ExecStop=/root/control_hdmi.sh off
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
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
cp ./play_videos.service /etc/systemd/system/play_videos.service
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
