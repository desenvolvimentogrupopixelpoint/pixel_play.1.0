#!/bin/bash

CONFIG_FILE="/boot/armbianEnv.txt"

# Adiciona um atraso de 5 segundos antes de executar qualquer ação
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
