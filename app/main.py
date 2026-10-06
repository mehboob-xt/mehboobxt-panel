import os
import psutil
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse, RedirectResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from sqlalchemy import select

from app.core.config import settings
from app.core.security import get_password_hash, decode_access_token
from app.db.database import init_db, AsyncSessionLocal
from app.db.models import Admin
from app.services.xray_service import XrayService

# Routers
from app.api.auth import router as auth_router
from app.api.xray import router as xray_router
from app.api.inbounds import router as inbounds_router
from app.api.clients import router as clients_router
from app.api.ssh import router as ssh_router

templates = Jinja2Templates(directory="/opt/mehboobxt/app/templates")

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
    await init_db()
    await seed_initial_admin()
    async with AsyncSessionLocal() as session:
        await XrayService.sync_database_to_xray(session)
    yield

app = FastAPI(
    title="MehboobXT Panel",
    description="High-Performance Enterprise VPS Management Panel (GUI + Xray + SSH)",
    version="4.0.0",
    lifespan=lifespan
)

# Mount Static Assets
app.mount("/static", StaticFiles(directory="/opt/mehboobxt/app/static"), name="static")

# Mount API Routers
app.include_router(auth_router)
app.include_router(xray_router)
app.include_router(inbounds_router)
app.include_router(clients_router)
app.include_router(ssh_router)

# Web UI Routes
@app.get("/", response_class=HTMLResponse)
async def index_view(request: Request):
    token = request.cookies.get("access_token")
    if token and decode_access_token(token):
        return RedirectResponse(url="/dashboard", status_code=302)
    return RedirectResponse(url="/login", status_code=302)

# ==============================================================================
# BUG FIX 2: Naya FastAPI/Starlette TemplateResponse Syntax
# ==============================================================================
@app.get("/login", response_class=HTMLResponse)
async def login_view(request: Request):
    token = request.cookies.get("access_token")
    if token and decode_access_token(token):
        return RedirectResponse(url="/dashboard", status_code=302)
    return templates.TemplateResponse(request=request, name="login.html")

@app.get("/dashboard", response_class=HTMLResponse)
async def dashboard_view(request: Request):
    token = request.cookies.get("access_token")
    if not token or not decode_access_token(token):
        return RedirectResponse(url="/login", status_code=302)
    return templates.TemplateResponse(request=request, name="dashboard.html")

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
