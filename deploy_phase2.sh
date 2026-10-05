cat << 'EOF' > /opt/mehboobxt/deploy_phase2.sh
#!/usr/bin/env bash
# ==============================================================================
# MehboobXT VPS Panel - Phase 2 Deployment Script
# Database Layer, Security Core & Authentication Endpoints
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

PANEL_DIR="/opt/mehboobxt"
APP_DIR="${PANEL_DIR}/app"

echo -e "\033[0;36m[INFO]\033[0m Writing Configuration Core (${APP_DIR}/core/config.py)..."
cat << 'PYEOF' > "${APP_DIR}/core/config.py"
import json
import os
from pydantic_settings import BaseSettings

CONFIG_PATH = "/opt/mehboobxt/config/panel_config.json"

class Settings(BaseSettings):
    host: str = "0.0.0.0"
    port: int = 2053
    secret_key: str = "default_secret_key_change_me"
    db_path: str = "/opt/mehboobxt/database/mehboobxt.db"
    xray_bin: str = "/opt/mehboobxt/bin/xray"
    xray_config: str = "/opt/mehboobxt/config/xray_config.json"
    log_dir: str = "/opt/mehboobxt/logs"
    access_token_expire_minutes: int = 60 * 24 * 7  # 7 Days

    class Config:
        case_sensitive = False

def load_settings() -> Settings:
    if os.path.exists(CONFIG_PATH):
        with open(CONFIG_PATH, "r", encoding="utf-8") as f:
            data = json.load(f)
            return Settings(**data)
    return Settings()

settings = load_settings()
PYEOF

echo -e "\033[0;36m[INFO]\033[0m Writing Cryptographic Security Engine (${APP_DIR}/core/security.py)..."
cat << 'PYEOF' > "${APP_DIR}/core/security.py"
import bcrypt
import jwt
from datetime import datetime, timezone, timedelta
from typing import Optional, Dict, Any
from app.core.config import settings

def get_password_hash(password: str) -> str:
    """Hashes password using bcrypt directly for zero-dependency bug safety."""
    salt = bcrypt.gensalt(rounds=12)
    return bcrypt.hashpw(password.encode("utf-8"), salt).decode("utf-8")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verifies a plain password against the stored bcrypt hash."""
    try:
        return bcrypt.checkpw(plain_password.encode("utf-8"), hashed_password.encode("utf-8"))
    except Exception:
        return False

def create_access_token(data: Dict[str, Any], expires_delta: Optional[timedelta] = None) -> str:
    """Generates an RFC 7519 compliant JWT access token."""
    to_encode = data.copy()
    now = datetime.now(timezone.utc)
    if expires_delta:
        expire = now + expires_delta
    else:
        expire = now + timedelta(minutes=settings.access_token_expire_minutes)
    
    to_encode.update({"iat": now, "exp": expire})
    return jwt.encode(to_encode, settings.secret_key, algorithm="HS256")

def decode_access_token(token: str) -> Optional[Dict[str, Any]]:
    """Decodes and validates a JWT token."""
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=["HS256"])
        return payload
    except jwt.PyJWTError:
        return None
PYEOF

echo -e "\033[0;36m[INFO]\033[0m Writing Async SQLite Engine (${APP_DIR}/db/database.py)..."
cat << 'PYEOF' > "${APP_DIR}/db/database.py"
from typing import AsyncGenerator
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import DeclarativeBase
from app.core.config import settings

DATABASE_URL = f"sqlite+aiosqlite:///{settings.db_path}"

engine = create_async_engine(
    DATABASE_URL,
    echo=False,
    connect_args={"check_same_thread": False}
)

AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    autocommit=False,
    autoflush=False,
    expire_on_commit=False,
    class_=AsyncSession
)

class Base(DeclarativeBase):
    pass

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """Dependency for providing database sessions per request."""
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()

async def init_db():
    """Initializes all tables defined in models."""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
PYEOF

echo -e "\033[0;36m[INFO]\033[0m Writing Production Data Models (${APP_DIR}/db/models.py)..."
cat << 'PYEOF' > "${APP_DIR}/db/models.py"
from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, Boolean, BigInteger, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.db.database import Base

def utc_now():
    return datetime.now(timezone.utc)

class Admin(Base):
    __tablename__ = "admins"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(64), unique=True, index=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)
    last_login = Column(DateTime(timezone=True), nullable=True)

class Inbound(Base):
    __tablename__ = "inbounds"

    id = Column(Integer, primary_key=True, index=True)
    tag = Column(String(64), unique=True, index=True, nullable=False)
    protocol = Column(String(32), nullable=False)  # vless, vmess, trojan, shadowsocks
    port = Column(Integer, unique=True, index=True, nullable=False)
    listen = Column(String(45), default="0.0.0.0", nullable=False)
    settings_json = Column(Text, default="{}", nullable=False)
    stream_settings_json = Column(Text, default="{}", nullable=False)
    sniffing_json = Column(Text, default="{}", nullable=False)
    up_bytes = Column(BigInteger, default=0, nullable=False)
    down_bytes = Column(BigInteger, default=0, nullable=False)
    total_limit_bytes = Column(BigInteger, default=0, nullable=False)  # 0 = unlimited
    expiry_timestamp = Column(BigInteger, default=0, nullable=False)   # 0 = unlimited
    is_enabled = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)

    clients = relationship("Client", back_populates="inbound", cascade="all, delete-orphan")

class Client(Base):
    __tablename__ = "clients"

    id = Column(Integer, primary_key=True, index=True)
    inbound_id = Column(Integer, ForeignKey("inbounds.id", ondelete="CASCADE"), nullable=True)
    email = Column(String(128), unique=True, index=True, nullable=False)
    uuid = Column(String(128), index=True, nullable=False)  # UUID or Trojan Password
    flow = Column(String(64), default="", nullable=True)     # e.g. xtls-rprx-vision
    up_bytes = Column(BigInteger, default=0, nullable=False)
    down_bytes = Column(BigInteger, default=0, nullable=False)
    total_limit_bytes = Column(BigInteger, default=0, nullable=False)
    expiry_timestamp = Column(BigInteger, default=0, nullable=False)
    is_enabled = Column(Boolean, default=True, nullable=False)
    client_type = Column(String(32), default="xray", nullable=False)  # 'xray' or 'ssh'
    created_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)

    inbound = relationship("Inbound", back_populates="clients")

class SSHTunnelUser(Base):
    __tablename__ = "ssh_tunnel_users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(32), unique=True, index=True, nullable=False)
    password = Column(String(128), nullable=False)
    expiry_date = Column(DateTime(timezone=True), nullable=True)
    max_connections = Column(Integer, default=2, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    up_bytes = Column(BigInteger, default=0, nullable=False)
    down_bytes = Column(BigInteger, default=0, nullable=False)
    created_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)

class SystemSetting(Base):
    __tablename__ = "system_settings"

    key = Column(String(64), primary_key=True, index=True)
    value = Column(Text, nullable=False)
PYEOF

echo -e "\033[0;36m[INFO]\033[0m Writing Authentication Router (${APP_DIR}/api/auth.py)..."
cat << 'PYEOF' > "${APP_DIR}/api/auth.py"
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status, Response, Request
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.db.database import get_db
from app.db.models import Admin
from app.core.security import verify_password, create_access_token, decode_access_token, get_password_hash

router = APIRouter(prefix="/api/auth", tags=["Authentication"])

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/token", auto_error=False)

class LoginRequest(BaseModel):
    username: str
    password: str

class PasswordChangeRequest(BaseModel):
    old_password: str
    new_password: str

async def get_current_admin(
    request: Request,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
) -> Admin:
    # Check Bearer Header or HTTP-Only Cookie
    jwt_token = token or request.cookies.get("access_token")
    if not jwt_token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication token missing",
            headers={"WWW-Authenticate": "Bearer"},
        )

    payload = decode_access_token(jwt_token)
    if not payload or "sub" not in payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        )

    username = payload["sub"]
    result = await db.execute(select(Admin).filter_by(username=username, is_active=True))
    admin = result.scalar_one_or_none()
    if not admin:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found or disabled")

    return admin

@router.post("/token")
async def login_for_access_token(
    response: Response,
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: AsyncSession = Depends(get_db)
):
    """Standard OAuth2 form login for Swagger docs and API clients."""
    result = await db.execute(select(Admin).filter_by(username=form_data.username))
    admin = result.scalar_one_or_none()

    if not admin or not verify_password(form_data.password, admin.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    admin.last_login = datetime.now(timezone.utc)
    await db.commit()

    token = create_access_token(data={"sub": admin.username})
    response.set_cookie(
        key="access_token",
        value=token,
        httponly=True,
        max_age=60 * 60 * 24 * 7,
        samesite="lax",
        secure=False
    )
    return {"access_token": token, "token_type": "bearer"}

@router.post("/login")
async def login_json(
    response: Response,
    credentials: LoginRequest,
    db: AsyncSession = Depends(get_db)
):
    """JSON-based login endpoint for Web Frontend."""
    result = await db.execute(select(Admin).filter_by(username=credentials.username))
    admin = result.scalar_one_or_none()

    if not admin or not verify_password(credentials.password, admin.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password"
        )

    admin.last_login = datetime.now(timezone.utc)
    await db.commit()

    token = create_access_token(data={"sub": admin.username})
    response.set_cookie(
        key="access_token",
        value=token,
        httponly=True,
        max_age=60 * 60 * 24 * 7,
        samesite="lax",
        secure=False
    )
    return {"success": True, "access_token": token, "token_type": "bearer"}

@router.post("/logout")
async def logout(response: Response):
    """Clears authentication cookies."""
    response.delete_cookie(key="access_token")
    return {"success": True, "message": "Logged out successfully"}

@router.get("/me")
async def get_me(current_admin: Admin = Depends(get_current_admin)):
    """Returns profile information for the authenticated admin."""
    return {
        "id": current_admin.id,
        "username": current_admin.username,
        "is_active": current_admin.is_active,
        "created_at": current_admin.created_at,
        "last_login": current_admin.last_login
    }

@router.post("/change-password")
async def change_password(
    data: PasswordChangeRequest,
    current_admin: Admin = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Allows authenticated admin to change their password."""
    if not verify_password(data.old_password, current_admin.password_hash):
        raise HTTPException(status_code=400, detail="Current password incorrect")

    current_admin.password_hash = get_password_hash(data.new_password)
    await db.commit()
    return {"success": True, "message": "Password changed successfully"}
PYEOF

echo -e "\033[0;36m[INFO]\033[0m Updating Master Application (${APP_DIR}/main.py)..."
cat << 'PYEOF' > "${APP_DIR}/main.py"
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
from app.api.auth import router as auth_router

async def seed_initial_admin():
    """Seeds default admin credentials if database is fresh."""
    async with AsyncSessionLocal() as session:
        result = await session.execute(select(Admin))
        admin = result.scalar_one_or_none()
        if not admin:
            # Default initial credentials
            default_admin = Admin(
                username="admin",
                password_hash=get_password_hash("admin")
            )
            session.add(default_admin)
            await session.commit()
            print("[INFO] Initial admin account seeded (username: 'admin', password: 'admin')")

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Database table creation & default admin seed
    await init_db()
    await seed_initial_admin()
    yield

app = FastAPI(
    title="MehboobXT Panel",
    description="High-Performance Enterprise VPS Management Panel",
    version="2.0.0",
    lifespan=lifespan
)

# Register API Routers
app.include_router(auth_router)

@app.get("/")
async def root():
    return {
        "status": "online",
        "panel": "MehboobXT Web Panel",
        "version": "2.0.0",
        "phase": "Phase 2 Core & Authentication Active",
        "endpoints": {
            "health": "/health",
            "docs": "/docs",
            "login": "/api/auth/login",
            "profile": "/api/auth/me"
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
PYEOF

echo -e "\033[0;36m[INFO]\033[0m Updating CLI Management Tool (${PANEL_DIR}/cli/mehboobxt.sh)..."
cat << 'SHELL_EOF' > "${PANEL_DIR}/cli/mehboobxt.sh"
#!/usr/bin/env bash
set -euo pipefail

PANEL_DIR="/opt/mehboobxt"
PYTHON_BIN="${PANEL_DIR}/venv/bin/python3"
PORT=$(jq -r '.port' "${PANEL_DIR}/config/panel_config.json" 2>/dev/null || echo "2053")

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

header() {
    clear
    echo -e "${CYAN}====================================================${NC}"
    echo -e "${GREEN}          MehboobXT Panel Management CLI           ${NC}"
    echo -e "${CYAN}====================================================${NC}"
}

reset_admin_password() {
    header
    echo -e "${YELLOW}Reset Admin Account Credentials${NC}"
    echo ""
    read -rp "Enter new username [admin]: " new_user
    new_user="${new_user:-admin}"
    read -rsp "Enter new password: " new_pass
    echo ""
    if [[ -z "${new_pass}" ]]; then
        echo -e "${RED}Error: Password cannot be blank.${NC}"
        return 1
    fi

    "${PYTHON_BIN}" - << EOF
import asyncio
from app.db.database import AsyncSessionLocal
from app.db.models import Admin
from app.core.security import get_password_hash
from sqlalchemy import select

async def update_creds():
    async with AsyncSessionLocal() as session:
        res = await session.execute(select(Admin).filter_by(username="${new_user}"))
        admin = res.scalar_one_or_none()
        if admin:
            admin.password_hash = get_password_hash("${new_pass}")
            print(f"Updated password for existing user: {admin.username}")
        else:
            admin = Admin(username="${new_user}", password_hash=get_password_hash("${new_pass}"))
            session.add(admin)
            print(f"Created new admin user: {admin.username}")
        await session.commit()

asyncio.run(update_creds())
EOF
    echo -e "${GREEN}Credentials successfully updated in database!${NC}"
}

cmd="${1:-menu}"

case "$cmd" in
    start)
        systemctl start mehboobxt
        echo -e "${GREEN}MehboobXT service started.${NC}"
        ;;
    stop)
        systemctl stop mehboobxt
        echo -e "${YELLOW}MehboobXT service stopped.${NC}"
        ;;
    restart)
        systemctl restart mehboobxt
        echo -e "${GREEN}MehboobXT service restarted.${NC}"
        ;;
    status)
        systemctl status mehboobxt --no-pager
        ;;
    logs)
        journalctl -u mehboobxt -f -n 50
        ;;
    reset-admin)
        reset_admin_password
        ;;
    info)
        IP=$(curl -s4 ifconfig.me || hostname -I | awk '{print $1}')
        header
        echo -e "Web Panel URL  : ${GREEN}http://${IP}:${PORT}${NC}"
        echo -e "API Swagger Doc: ${GREEN}http://${IP}:${PORT}/docs${NC}"
        echo -e "Install Path   : ${CYAN}${PANEL_DIR}${NC}"
        echo -e "Service Status : $(systemctl is-active mehboobxt)"
        echo -e "${CYAN}====================================================${NC}"
        ;;
    menu|*)
        header
        IP=$(curl -s4 ifconfig.me || hostname -I | awk '{print $1}')
        echo -e "Panel Status : $(systemctl is-active mehboobxt)"
        echo -e "Web URL      : http://${IP}:${PORT}"
        echo ""
        echo "1) Start Panel"
        echo "2) Stop Panel"
        echo "3) Restart Panel"
        echo "4) View Service Status"
        echo "5) View Live Service Logs"
        echo "6) Reset Admin Credentials"
        echo "7) System Info & Health"
        echo "0) Exit"
        echo ""
        read -rp "Select option [0-7]: " opt
        case "$opt" in
            1) systemctl start mehboobxt && echo -e "${GREEN}Started.${NC}" ;;
            2) systemctl stop mehboobxt && echo -e "${YELLOW}Stopped.${NC}" ;;
            3) systemctl restart mehboobxt && echo -e "${GREEN}Restarted.${NC}" ;;
            4) systemctl status mehboobxt --no-pager ;;
            5) journalctl -u mehboobxt -f -n 50 ;;
            6) reset_admin_password ;;
            7) "${PANEL_DIR}/cli/mehboobxt.sh" info ;;
            0) exit 0 ;;
            *) echo -e "${RED}Invalid option.${NC}" ;;
        esac
        ;;
esac
SHELL_EOF

chmod +x "${PANEL_DIR}/cli/mehboobxt.sh"
ln -sf "${PANEL_DIR}/cli/mehboobxt.sh" /usr/local/bin/mehboobxt

echo -e "\033[0;36m[INFO]\033[0m Restarting mehboobxt.service with Phase 2 stack..."
systemctl restart mehboobxt.service

echo -e "\033[0;32m[OK]\033[0m Phase 2 successfully deployed!"

chmod +x /opt/mehboobxt/deploy_phase2.sh
