#!/bin/bash

# Atualização do sistema
echo "Atualizando o sistema..."
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && sudo apt clean

# Instalação de pacotes necessários
echo "Instalando pacotes necessários..."
sudo apt install -y mpv fim python3 python3-pip python3-venv python3-dev libdrm-dev libx11-dev libva-dev libvdpau-dev libxcb-shm0-dev libxext-dev libxcb1-dev libasound2-dev mesa-va-drivers mesa-vdpau-drivers vdpauinfo vainfo

# Criando diretórios necessários
echo "Criando diretórios..."
mkdir -p ~/.config/mpv
mkdir -p /home/pixelpoint/templates
mkdir -p /home/pixelpoint/videos
mkdir -p /home/pixelpoint/midias_inativas

# Configurando permissões
echo "Configurando permissões..."
chmod -R 777 ~/.config/mpv
chmod -R 777 /home/pixelpoint

# Criando arquivo mpv.conf
echo "Criando arquivo mpv.conf..."
cat <<EOF > ~/.config/mpv/mpv.conf
hwdec=auto
vo=gpu
gpu-context=x11
EOF

# Copiando arquivos estáticos
echo "Copiando arquivos estáticos..."
cp ./Logo.png /home/pixelpoint/
cp ./templates/index.html /home/pixelpoint/templates/
cp ./templates/logop.png /home/pixelpoint/templates/

# Criando metadata.json
echo "Criando metadata.json..."
echo "{}" > /home/pixelpoint/metadata.json

# Configurando serviços
echo "Configurando serviços..."
cp ./control_hdmi.sh /root/control_hdmi.sh
chmod +x /root/control_hdmi.sh

cp ./play_videos.service /etc/systemd/system/play_videos.service
chmod 644 /etc/systemd/system/play_videos.service

# Ativando serviços
echo "Ativando serviços..."
sudo systemctl enable play_videos.service
sudo systemctl start play_videos.service

# Configurando cron jobs
echo "Configurando cron jobs..."
(crontab -l 2>/dev/null; echo "30 22 * * * /root/control_hdmi.sh off") | crontab -
(crontab -l 2>/dev/null; echo "55 7 * * * /root/control_hdmi.sh on") | crontab -
sudo systemctl restart cron

# Configurando rc.local
echo "Configurando rc.local..."
cat <<EOF > /etc/rc.local
#!/bin/bash
(sleep 4 && fim -q -a /home/pixelpoint/Logo.png) &
exit 0
EOF
chmod +x /etc/rc.local
sudo /etc/rc.local

# Instalando e configurando Tailscale
echo "Instalando Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh
sudo systemctl enable tailscaled
sudo systemctl start tailscaled
sudo tailscale status

# Finalizando
echo "Instalação concluída!"
