import json
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from typing import List
from app.db.database import get_db
from app.db.models import Admin, Inbound, Client
from app.api.auth import get_current_admin
from app.schemas.xray import InboundCreate, InboundUpdate, InboundResponse, StreamSettings
from app.services.xray_service import XrayService

router = APIRouter(prefix="/api/inbounds", tags=["Inbound Management"])

@router.get("", response_model=List[InboundResponse])
async def list_inbounds(db: AsyncSession = Depends(get_db), _: Admin = Depends(get_current_admin)):
    result = await db.execute(select(Inbound))
    inbounds = result.scalars().all()
    out = []
    for ib in inbounds:
        count_res = await db.execute(select(func.count(Client.id)).filter_by(inbound_id=ib.id))
        count = count_res.scalar() or 0
        stream_data = json.loads(ib.stream_settings_json) if ib.stream_settings_json else {}
        out.append(InboundResponse(
            id=ib.id,
            tag=ib.tag,
            protocol=ib.protocol,
            port=ib.port,
            listen=ib.listen,
            stream=StreamSettings(**stream_data),
            sniffing_enabled=True,
            up_bytes=ib.up_bytes,
            down_bytes=ib.down_bytes,
            total_limit_bytes=ib.total_limit_bytes,
            expiry_timestamp=ib.expiry_timestamp,
            is_enabled=ib.is_enabled,
            client_count=count
        ))
    return out

@router.post("", status_code=status.HTTP_201_CREATED)
async def create_inbound(
    payload: InboundCreate,
    db: AsyncSession = Depends(get_db),
    _: Admin = Depends(get_current_admin)
):
    # Verify port / tag conflict
    existing = await db.execute(select(Inbound).filter((Inbound.port == payload.port) | (Inbound.tag == payload.tag)))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Inbound port or tag already in use.")

    inbound = Inbound(
        tag=payload.tag,
        protocol=payload.protocol,
        port=payload.port,
        listen=payload.listen,
        stream_settings_json=json.dumps(payload.stream.model_dump()),
        sniffing_json=json.dumps({"enabled": payload.sniffing_enabled}),
        total_limit_bytes=payload.total_limit_bytes,
        expiry_timestamp=payload.expiry_timestamp,
        is_enabled=payload.is_enabled
    )
    db.add(inbound)
    await db.commit()
    await db.refresh(inbound)

    # Sync to Xray
    ok, msg = await XrayService.sync_database_to_xray(db)
    if not ok:
        await db.delete(inbound)
        await db.commit()
        raise HTTPException(status_code=400, detail=f"Xray rejection: {msg}")

    return {"success": True, "id": inbound.id, "message": "Inbound created and synced."}

@router.delete("/{inbound_id}")
async def delete_inbound(
    inbound_id: int,
    db: AsyncSession = Depends(get_db),
    _: Admin = Depends(get_current_admin)
):
    res = await db.execute(select(Inbound).filter_by(id=inbound_id))
    inbound = res.scalar_one_or_none()
    if not inbound:
        raise HTTPException(status_code=404, detail="Inbound not found")

    await db.delete(inbound)
    await db.commit()
    await XrayService.sync_database_to_xray(db)
    return {"success": True, "message": "Inbound removed and Xray re-synced."}
