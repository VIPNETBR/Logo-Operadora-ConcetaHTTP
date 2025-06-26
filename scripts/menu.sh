#!/bin/bash
DB="../backend.db"

function pause() {
    read -p "Presione Enter para continuar..."
}

function check_db() {
    if [ ! -f "$DB" ]; then
        echo "Base de datos no encontrada: $DB"
        exit 1
    fi
}

function listar_clientes() {
    check_db
    echo "ID | IP           | IDENTIFICADOR | VENCIMIENTO | ESTADO"
    sqlite3 "$DB" "SELECT id, ip, identifier, fecha_vencimiento, estado FROM clients;" | while IFS="|" read -r id ip identifier venc estado; do
        if [ "$estado" -eq 1 ]; then estado_text="Activo"; else estado_text="Inactivo"; fi
        echo "$id | $ip | $identifier | $venc | $estado_text"
    done
    pause
}

function agregar_cliente() {
    check_db
    read -p "IP cliente: " ip
    read -p "Identificador (ej: 020): " idf
    read -p "Días de vencimiento: " dias

    venc=$(date -d "+$dias days" +%Y-%m-%d)
    sqlite3 "$DB" "INSERT INTO clients (ip, identifier, fecha_vencimiento, estado) VALUES ('$ip', '$idf', '$venc', 1);"
    echo "Cliente agregado con vencimiento $venc"
    pause
}

function editar_cliente() {
    check_db
    listar_clientes
    read -p "Ingrese ID del cliente a editar: " id
    read -p "Nueva IP: " ip
    read -p "Nuevo identificador: " idf
    sqlite3 "$DB" "UPDATE clients SET ip='$ip', identifier='$idf' WHERE id=$id;"
    echo "Cliente actualizado."
    pause
}

function renovar_cliente() {
    check_db
    listar_clientes
    read -p "Ingrese ID del cliente a renovar: " id
    read -p "Días a agregar: " dias

    venc_actual=$(sqlite3 "$DB" "SELECT fecha_vencimiento FROM clients WHERE id=$id;")
    fecha_base=$(date -d "$venc_actual" +%s)
    ahora=$(date +%s)
    if [ $fecha_base -lt $ahora ]; then
        fecha_base=$ahora
    fi
    nueva_fecha=$(date -d "@$((fecha_base + dias*86400))" +%Y-%m-%d)
    sqlite3 "$DB" "UPDATE clients SET fecha_vencimiento='$nueva_fecha' WHERE id=$id;"
    echo "Cliente renovado hasta $nueva_fecha"
    pause
}

function remover_cliente() {
    check_db
    listar_clientes
    read -p "Ingrese ID del cliente a eliminar: " id
    sqlite3 "$DB" "DELETE FROM clients WHERE id=$id;"
    echo "Cliente eliminado."
    pause
}

function ver_cdn() {
    check_db
    cdn=$(sqlite3 "$DB" "SELECT value FROM config WHERE key='cdn_domain';")
    echo "Dominio CDN actual: $cdn"
    pause
}

function cambiar_cdn() {
    check_db
    read -p "Nuevo dominio CDN: " cdn
    sqlite3 "$DB" "INSERT OR REPLACE INTO config (key, value) VALUES ('cdn_domain', '$cdn');"
    echo "Dominio CDN actualizado."
    pause
}

function menu_principal() {
    while true; do
        clear
        echo "=== Menú Principal Bakken ==="
        echo "1) Listar Clientes"
        echo "2) Agregar Cliente"
        echo "3) Editar Cliente"
        echo "4) Renovar Cliente"
        echo "5) Remover Cliente"
        echo "6) Ver Dominio CDN"
        echo "7) Cambiar Dominio CDN"
        echo "8) Salir"
        read -p "Seleccione una opción: " opcion

        case $opcion in
            1) listar_clientes ;;
            2) agregar_cliente ;;
            3) editar_cliente ;;
            4) renovar_cliente ;;
            5) remover_cliente ;;
            6) ver_cdn ;;
            7) cambiar_cdn ;;
            8) echo "Saliendo..."; exit 0 ;;
            *) echo "Opción inválida."; pause ;;
        esac
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    menu_principal
fi
