# Sistema Backend Bakken para VPS Ubuntu 20/22/24

## Requisitos

- VPS con Ubuntu 20.04, 22.04 o 24.04
- Acceso root o sudo

## Instalación

1. Sube todo el contenido a tu VPS.
2. Ejecuta el script de instalación:
   ```bash
   sudo bash install.sh
   ```
3. El backend arrancará en puerto 80, con Nginx como proxy reverso.

## Administración

- Para administrar clientes y CDN ejecuta:
  ```bash
  /opt/bakken/menu.sh
  ```

- El menú te permite agregar, editar, renovar, eliminar clientes y cambiar dominio CDN.

## Uso WebSocket

- Los clientes se conectan vía WebSocket en puerto 80 al dominio configurado.
- Deben enviar en el payload JSON el identificador de cliente:
  ```json
  {"identifier":"020"}
  ```
- El servidor valida IP + identificador + vencimiento antes de aceptar conexión.

---

## Nota

- Puedes migrar o reinstalar en otra máquina copiando `/opt/bakken/backend.db` para conservar datos.

- Para más personalizaciones modifica los archivos en `/opt/bakken/`.

---

- Instalación directa:
```bash
  bash <(curl -s https://raw.githubusercontent.com/VIPNETBR/bakken-backend/main/install.sh)
```
# ¡Listo para usar!
