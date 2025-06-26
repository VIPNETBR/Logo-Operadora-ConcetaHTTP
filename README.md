# 🔥 Bakken Backend - Sistema de Validación por IP + Identificador

Este es un backend ligero basado en **FastAPI + Uvicorn**, con soporte completo para **WebSocket** en el puerto 80 y validación mediante **identificador, IP y fecha de vencimiento**. Incluye sistema automático de instalación, servicio persistente (`systemd`) y menú de administración.

---

## ⚙️ Requisitos

- VPS Ubuntu 20.04, 22.04 o 24.04 (64 bits)
- Acceso como root
- Puerto 80 disponible (para WebSocket y HTTP)
- Dominio opcional (puede funcionar solo con IP pública)

---

## 🚀 Instalación (automática en 1 línea)

Ejecuta este comando como `root` en tu VPS:

```bash
bash <(curl -s https://raw.githubusercontent.com/VIPNETBR/bakken-backend/main/install.sh)
