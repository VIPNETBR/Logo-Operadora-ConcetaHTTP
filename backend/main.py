import sqlite3
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from datetime import datetime, timedelta
import uvicorn

DB_PATH = "./backend.db"

app = FastAPI(title="Bakken Backend CDN WebSocket")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def validate_client(ip: str, identifier: str):
    conn = get_db()
    cur = conn.cursor()
    cur.execute("SELECT * FROM clients WHERE ip=? AND identifier=? AND estado=1", (ip, identifier))
    row = cur.fetchone()
    conn.close()
    if not row:
        return False, "Cliente no encontrado o inactivo"
    venc = datetime.strptime(row["fecha_vencimiento"], "%Y-%m-%d")
    if venc < datetime.utcnow():
        return False, "Cliente vencido"
    return True, "Cliente válido"

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    try:
        # Esperamos mensaje inicial con JSON: {"identifier":"020"}
        data = await websocket.receive_json()
        identifier = data.get("identifier")
        ip = websocket.client.host
        valid, msg = validate_client(ip, identifier)
        if not valid:
            await websocket.send_json({"error": msg})
            await websocket.close()
            return
        await websocket.send_json({"message": f"Conexión aceptada para cliente {identifier}"})

        while True:
            msg = await websocket.receive_text()
            # Aquí puedes procesar mensajes para túnel SSH, etc.
            await websocket.send_text(f"Eco: {msg}")

    except WebSocketDisconnect:
        print(f"Cliente {identifier} desconectado")
    except Exception as e:
        print(f"Error WebSocket: {e}")
        await websocket.close()

@app.get("/clients")
def list_clients():
    conn = get_db()
    cur = conn.cursor()
    cur.execute("SELECT id, ip, identifier, fecha_vencimiento, estado FROM clients")
    rows = cur.fetchall()
    conn.close()
    return [dict(r) for r in rows]

@app.get("/config")
def get_config():
    conn = get_db()
    cur = conn.cursor()
    cur.execute("SELECT value FROM config WHERE key='cdn_domain'")
    row = cur.fetchone()
    conn.close()
    return {"cdn_domain": row["value"] if row else ""}

@app.post("/config")
def set_config(domain: str):
    conn = get_db()
    cur = conn.cursor()
    cur.execute("INSERT OR REPLACE INTO config (key, value) VALUES ('cdn_domain', ?)", (domain,))
    conn.commit()
    conn.close()
    return {"message": "Dominio CDN actualizado"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=80)
