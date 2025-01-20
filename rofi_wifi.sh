#!/bin/bash

# Configuración
ROFI_CMD="rofi -dmenu -p 'WiFi' -i"
NMCLI_CMD="nmcli"
TEMP_FILE="/tmp/wifi_password"

# Función para mostrar un mensaje de error
error_msg() {
    echo "$1" | rofi -dmenu -p "Error" -lines 0
}

# Listar redes WiFi
list_networks() {
    $NMCLI_CMD -t -f SSID,SIGNAL,SECURITY dev wifi list | awk -F: '
    {
        printf "%-30s | %-10s | %s\n", $1, $2"%", $3
    }' | $ROFI_CMD
}

# Conectar a una red WiFi
connect_to_network() {
    local ssid="$1"
    local security="$2"

    if [[ "$security" == "--" ]]; then
        # Conexión a red abierta
        $NMCLI_CMD dev wifi connect "$ssid" >/dev/null 2>&1
        if [[ $? -eq 0 ]]; then
            notify-send "WiFi Manager" "Conectado a $ssid"
        else
            error_msg "No se pudo conectar a $ssid"
        fi
    else
        # Conexión a red protegida
        local password
        password=$(echo "" | rofi -dmenu -password -p "Contraseña para $ssid")
        if [[ -n "$password" ]]; then
            echo "$password" >"$TEMP_FILE"
            $NMCLI_CMD dev wifi connect "$ssid" password "$(cat "$TEMP_FILE")" >/dev/null 2>&1
            rm -f "$TEMP_FILE"
            if [[ $? -eq 0 ]]; then
                notify-send "WiFi Manager" "Conectado a $ssid"
            else
                error_msg "No se pudo conectar a $ssid"
            fi
        fi
    fi
}

# Inicio del script
main() {
    local selection
    local ssid
    local signal
    local security

    selection=$(list_networks)
    if [[ -z "$selection" ]]; then
        exit 0
    fi

    ssid=$(echo "$selection" | awk -F'|' '{print $1}' | xargs)
    signal=$(echo "$selection" | awk -F'|' '{print $2}' | xargs)
    security=$(echo "$selection" | awk -F'|' '{print $3}' | xargs)

    connect_to_network "$ssid" "$security"
}

main