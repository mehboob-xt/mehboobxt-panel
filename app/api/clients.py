import uuid as uuid_pkg
import socket
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List
from app.db.database import get_db
from app.db.models import Admin, Client, Inbound
from app.api.auth import get_current_admin
from app.schemas.xray import ClientCreate, ClientResponse, ClientUpdate
from app.services.xray_service import XrayService

router = APIRouter(prefix="/api/clients", tags=["Client Management"])

def get_server_ip() -> str:
    try:
        import httpx
        with httpx.Client(timeout=2.0) as client:
            return client.get("https://api.ipify.org").text.strip()
    except Exception:
        return "127.0.0.1"

@router.get("", response_model=List[ClientResponse])
async def list_clients(db: AsyncSession = Depends(get_db), _: Admin = Depends(get_current_admin)):
    res = await db.execute(select(Client).filter_by(client_type="xray"))
    clients = res.scalars().all()
    server_ip = get_server_ip()
    out = []
    for cl in clients:
        ib_res = await db.execute(select(Inbound).filter_by(id=cl.inbound_id))
        ib = ib_res.scalar_one_or_none()
        link = XrayService.generate_share_link(cl, ib, server_ip) if ib else ""
        out.append(ClientResponse(
            id=cl.id,
            inbound_id=cl.inbound_id,
            email=cl.email,
            uuid=cl.uuid,
            flow=cl.flow,
            up_bytes=cl.up_bytes,
            down_bytes=cl.down_bytes,
            total_limit_bytes=cl.total_limit_bytes,
            expiry_timestamp=cl.expiry_timestamp,
            is_enabled=cl.is_enabled,
            client_type=cl.client_type,
            share_link=link
        ))
    return out

@router.post("", status_code=status.HTTP_201_CREATED)
async def create_client(
    payload: ClientCreate,
    db: AsyncSession = Depends(get_db),
    _: Admin = Depends(get_current_admin)
):
    ib_res = await db.execute(select(Inbound).filter_by(id=payload.inbound_id))
    inbound = ib_res.scalar_one_or_none()
    if not inbound:
        raise HTTPException(status_code=404, detail="Referenced inbound does not exist.")

    existing_email = await db.execute(select(Client).filter_by(email=payload.email))
    if existing_email.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Client email already exists.")

    final_uuid = payload.uuid or str(uuid_pkg.uuid4())

    client = Client(
        inbound_id=payload.inbound_id,
        email=payload.email,
        uuid=final_uuid,
        flow=payload.flow or "",
        total_limit_bytes=payload.total_limit_bytes,
        expiry_timestamp=payload.expiry_timestamp,
        is_enabled=payload.is_enabled,
        client_type="xray"
    )
    db.add(client)
    await db.commit()
    await db.refresh(client)

    ok, msg = await XrayService.sync_database_to_xray(db)
    if not ok:
        await db.delete(client)
        await db.commit()
        raise HTTPException(status_code=400, detail=f"Xray rejected updated client: {msg}")

    return {"success": True, "id": client.id, "uuid": client.uuid, "message": "Client created successfully."}

@router.delete("/{client_id}")
async def delete_client(
    client_id: int,
    db: AsyncSession = Depends(get_db),
    _: Admin = Depends(get_current_admin)
):
    res = await db.execute(select(Client).filter_by(id=client_id))
    client = res.scalar_one_or_none()
    if not client:
        raise HTTPException(status_code=404, detail="Client not found")

    await db.delete(client)
    await db.commit()
    await XrayService.sync_database_to_xray(db)
    return {"success": True, "message": "Client removed successfully."}
