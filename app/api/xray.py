from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.database import get_db
from app.db.models import Admin
from app.api.auth import get_current_admin
from app.core.xray_engine import XrayEngine
from app.services.xray_service import XrayService

router = APIRouter(prefix="/api/xray", tags=["Xray Engine"])

@router.get("/status")
async def get_status(_: Admin = Depends(get_current_admin)):
    return XrayEngine.get_status()

@router.post("/restart")
async def restart_xray(_: Admin = Depends(get_current_admin)):
    ok, msg = XrayEngine.restart_service()
    if not ok:
        raise HTTPException(status_code=500, detail=msg)
    return {"success": True, "message": msg}

@router.post("/sync")
async def sync_xray(db: AsyncSession = Depends(get_db), _: Admin = Depends(get_current_admin)):
    ok, msg = await XrayService.sync_database_to_xray(db)
    if not ok:
        raise HTTPException(status_code=400, detail=msg)
    return {"success": True, "message": msg}

@router.get("/reality/keypair")
async def get_reality_keypair(_: Admin = Depends(get_current_admin)):
    keys = XrayEngine.generate_reality_keypair()
    if not keys.get("private_key"):
        raise HTTPException(status_code=500, detail="Failed to generate keys via Xray binary.")
    return keys
