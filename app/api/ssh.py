from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List
from app.db.database import get_db
from app.db.models import Admin, SSHTunnelUser
from app.api.auth import get_current_admin
from app.schemas.ssh import SSHTunnelUserCreate, SSHTunnelUserUpdate, SSHTunnelUserResponse
from app.services.ssh_service import SSHService

router = APIRouter(prefix="/api/ssh/users", tags=["SSH Tunnel Subsystem"])

@router.get("", response_model=List[SSHTunnelUserResponse])
async def list_ssh_users(db: AsyncSession = Depends(get_db), _: Admin = Depends(get_current_admin)):
    res = await db.execute(select(SSHTunnelUser))
    return res.scalars().all()

@router.post("", status_code=status.HTTP_201_CREATED)
async def create_ssh_user(
    payload: SSHTunnelUserCreate,
    db: AsyncSession = Depends(get_db),
    _: Admin = Depends(get_current_admin)
):
    res = await db.execute(select(SSHTunnelUser).filter_by(username=payload.username))
    if res.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="SSH tunnel username already exists.")

    ok, msg = SSHService.create_system_user(payload.username, payload.password, payload.expiry_date)
    if not ok:
        raise HTTPException(status_code=400, detail=msg)

    user = SSHTunnelUser(
        username=payload.username,
        password=payload.password,
        expiry_date=payload.expiry_date,
        max_connections=payload.max_connections,
        is_active=payload.is_active
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)

    return {"success": True, "id": user.id, "message": f"User {user.username} created on system and database."}

@router.delete("/{user_id}")
async def delete_ssh_user(
    user_id: int,
    db: AsyncSession = Depends(get_db),
    _: Admin = Depends(get_current_admin)
):
    res = await db.execute(select(SSHTunnelUser).filter_by(id=user_id))
    user = res.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    SSHService.delete_system_user(user.username)
    await db.delete(user)
    await db.commit()
    return {"success": True, "message": f"User {user.username} deleted from Linux system and DB."}
