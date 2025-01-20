#!/bin/bash

# Função para verificar o sucesso da execução de comandos
check_success() {
    if [ $? -ne 0 ]; then
        echo "Erro ao executar: $1"
        exit 1
    fi
}

# Atualização do sistema
echo "Atualizando o sistema..."
sudo apt update
check_success "Atualização do sistema"
sudo apt upgrade -y
check_success "Atualização de pacotes"
sudo apt autoremove -y
check_success "Remoção de pacotes obsoletos"
sudo apt clean
check_success "Limpeza de pacotes"

# Verificando se o sistema está ativo
echo "Verificando o status do sistema..."
sudo systemctl status ssh | grep -E "enabled|active" || echo "SSH não está ativo ou habilitado."

# Instalando pacotes necessários
echo "Instalando pacotes necessários..."
sudo apt install -y mpv fim python3 python3-pip python3-venv python3-dev \
libdrm-dev libx11-dev libva-dev libvdpau-dev libxcb-shm0-dev libxext-dev \
libxcb1-dev libasound2-dev mesa-va-drivers mesa-vdpau-drivers vdpauinfo vainfo
check_success "Instalação de pacotes"

# Criando pastas e ajustando permissões
echo "Criando pastas e configurando permissões..."
mkdir -p ~/.config/mpv
check_success "Criação de ~/.config/mpv"
chmod -R 777 ~/.config/mpv
mkdir -p /home/pixelpoint/templates /home/pixelpoint/videos /home/pixelpoint/midias_inativas
check_success "Criação de diretórios em /home/pixelpoint"
chmod -R 777 /home /home/pixelpoint /home/pixelpoint/templates /home/pixelpoint/videos /home/pixelpoint/midias_inativas

# Criando o arquivo mpv.conf
echo "Configurando mpv.conf..."
cat <<EOF > ~/.config/mpv/mpv.conf
hwdec=auto
vo=gpu
gpu-context=x11
EOF
check_success "Criação de ~/.config/mpv/mpv.conf"

# Movendo arquivos para os diretórios apropriados
echo "Movendo arquivos para os diretórios..."
cp ./Logo.png /home/pixelpoint/
cp ./templates/index.html /home/pixelpoint/templates/
cp ./templates/logop.png /home/pixelpoint/templates/
cp ./control_hdmi.sh /root/control_hdmi.sh
chmod +x /root/control_hdmi.sh
check_success "Movimento de arquivos e configuração do script control_hdmi.sh"
echo "{}" > /home/pixelpoint/metadata.json
check_success "Criação de /home/pixelpoint/metadata.json"

# Substituindo o conteúdo do arquivo sudoers
echo "Substituindo o conteúdo do arquivo sudoers..."
cat <<EOF > /etc/sudoers
#
# This file MUST be edited with the 'visudo' command as root.
#
Defaults        env_reset
Defaults        mail_badpass
Defaults        secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
Defaults        use_pty

root    ALL=(ALL:ALL) ALL
%sudo   ALL=(ALL:ALL) ALL

@includedir /etc/sudoers.d
root ALL=(ALL) NOPASSWD: /sbin/reboot
EOF
check_success "Substituição do arquivo sudoers"

# Configurando cron para desligar e ligar HDMI
echo "Configurando cron..."
(crontab -l 2>/dev/null; echo "30 22 * * * /root/control_hdmi.sh off") | crontab -
(crontab -l 2>/dev/null; echo "55 7 * * * /root/control_hdmi.sh on") | crontab -
check_success "Configuração do crontab"
sudo systemctl restart cron
check_success "Reinício do serviço cron"

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
sudo systemctl daemon-reload
check_success "Recarregando configurações do systemd"
sudo systemctl enable hdmi_control.service
sudo systemctl start hdmi_control.service
check_success "Configuração do serviço hdmi_control"

# Configurando rc.local
echo "Configurando rc.local..."
cat <<EOF > /etc/rc.local
#!/bin/bash
(sleep 4 && fim -q -a /home/pixelpoint/Logo.png) &
exit 0
EOF
chmod +x /etc/rc.local
check_success "Criação e configuração de /etc/rc.local"
sudo /etc/rc.local

# Configurando o serviço play_videos
echo "Configurando serviço play_videos..."
cp ./play_videos.service /etc/systemd/system/play_videos.service
chmod 644 /etc/systemd/system/play_videos.service
sudo systemctl daemon-reload
sudo systemctl enable play_videos.service
sudo systemctl start play_videos.service
check_success "Configuração do serviço play_videos"

# Instalando e configurando Tailscale
echo "Instalando e configurando Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh
sudo systemctl enable tailscaled
sudo systemctl start tailscaled
check_success "Configuração do Tailscale"

# Finalizando
echo "Instalação concluída com sucesso!"
