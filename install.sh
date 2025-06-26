#!/bin/bash
set -e

echo "Instalando sistema Bakken Backend..."

# Detectar versión de Ubuntu (20,22,24)
ver=$(lsb_release -rs | cut -d'.' -f1)
if [[ "$ver" != "20" && "$ver" != "22" && "$ver" != "24" ]]; then
  echo "Versión de Ubuntu no soportada: $ver"
  exit 1
fi

echo "Versión de Ubuntu detectada: $ver"

# Actualizar paquetes e instalar dependencias
apt update && apt upgrade -y
apt install -y python3 python3-pip python3-venv nginx sqlite3

# Crear entorno virtual e instalar dependencias Python
python3 -m venv /opt/bakken_env
source /opt/bakken_env/bin/activate
pip install --upgrade pip
pip install fastapi uvicorn[standard]

# Crear base de datos SQLite si no existe
DB_PATH="/opt/bakken/backend.db"
if [ ! -f "$DB_PATH" ]; then
cat > /tmp/create_tables.sql <<EOF
CREATE TABLE IF NOT EXISTS clients (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ip TEXT NOT NULL,
    identifier TEXT NOT NULL,
    fecha_vencimiento TEXT NOT NULL,
    estado INTEGER DEFAULT 1
);
CREATE TABLE IF NOT EXISTS config (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
);
EOF
    sqlite3 "$DB_PATH" < /tmp/create_tables.sql
    echo "Base de datos creada en $DB_PATH."
else
    echo "Base de datos existente detectada en $DB_PATH."
fi

# Copiar backend y scripts a /opt/bakken
mkdir -p /opt/bakken
cp backend/main.py /opt/bakken/
cp scripts/menu.sh /opt/bakken/
chmod +x /opt/bakken/menu.sh

# Ajustar DB_PATH para menu.sh (se asume relativo a /opt/bakken)
sed -i 's|DB="../backend.db"|DB="/opt/bakken/backend.db"|' /opt/bakken/menu.sh

# Crear servicio systemd para uvicorn
cat > /etc/systemd/system/bakken.service <<EOF
[Unit]
Description=Bakken Backend FastAPI Service
After=network.target

[Service]
User=root
WorkingDirectory=/opt/bakken
Environment="PATH=/opt/bakken_env/bin"
ExecStart=/opt/bakken_env/bin/uvicorn main:app --host 0.0.0.0 --port 80
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Recargar systemd e iniciar servicio
systemctl daemon-reload
systemctl enable bakken.service
systemctl start bakken.service

# Configurar Nginx proxy para WebSocket en puerto 80
cat > /etc/nginx/sites-available/bakken <<EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:80;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

ln -sf /etc/nginx/sites-available/bakken /etc/nginx/sites-enabled/bakken
nginx -t && systemctl restart nginx

echo "Instalación completada."
echo "Ejecuta '/opt/bakken/menu.sh' para administrar el sistema."
