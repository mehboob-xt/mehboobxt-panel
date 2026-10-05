import os
import psutil
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.responses import JSONResponse
from sqlalchemy import select
from app.core.config import settings
from app.core.security import get_password_hash
from app.db.database import init_db, AsyncSessionLocal
from app.db.models import Admin
from app.services.xray_service import XrayService

# Routers
from app.api.auth import router as auth_router
from app.api.xray import router as xray_router
from app.api.inbounds import router as inbounds_router
from app.api.clients import router as clients_router
from app.api.ssh import router as ssh_router

async def seed_initial_admin():
    async with AsyncSessionLocal() as session:
        result = await session.execute(select(Admin))
        if not result.scalar_one_or_none():
            default_admin = Admin(
                username="admin",
                password_hash=get_password_hash("admin")
            )
            session.add(default_admin)
            await session.commit()
            print("[INFO] Initial admin account verified.")

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup sequence
    await init_db()
    await seed_initial_admin()
    async with AsyncSessionLocal() as session:
        # Sync initial state to Xray
        await XrayService.sync_database_to_xray(session)
    yield

app = FastAPI(
    title="MehboobXT Panel",
    description="High-Performance Enterprise VPS Management Panel (Xray & SSH)",
    version="3.0.0",
    lifespan=lifespan
)

# Register API Routers
app.include_router(auth_router)
app.include_router(xray_router)
app.include_router(inbounds_router)
app.include_router(clients_router)
app.include_router(ssh_router)

@app.get("/")
async def root():
    return {
        "status": "online",
        "panel": "MehboobXT Web Panel",
        "version": "3.0.0",
        "phase": "Phase 3 Operational (Xray Core + SSH Subsystem)",
        "features": [
            "VLESS-Reality",
            "VMess",
            "Trojan",
            "Native SSH Tunnel Isolation",
            "Deterministic Xray Sync"
        ],
        "endpoints": {
            "docs": "/docs",
            "health": "/health",
            "xray_status": "/api/xray/status",
            "inbounds": "/api/inbounds",
            "clients": "/api/clients",
            "ssh_users": "/api/ssh/users"
        }
    }

@app.get("/health")
async def health():
    return JSONResponse(
        status_code=200,
        content={
            "status": "healthy",
            "system": {
                "cpu_usage_percent": psutil.cpu_percent(interval=None),
                "ram_usage_percent": psutil.virtual_memory().percent,
                "disk_usage_percent": psutil.disk_usage("/").percent
            },
            "xray_binary_exists": os.path.isfile(settings.xray_bin),
            "db_path": settings.db_path
        }
    )
