import json
import socket
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

def verify_socket_bindable(port: int, host: str = "0.0.0.0") -> tuple[bool, str]:
    """
    Performs active Linux TCP socket pre-flight checks across IPv4 and IPv6
    to prevent EADDRINUSE collisions before modifying DB or Xray.
    """
    # 1. System Reserved Ports Check
    if port in (22, 80, 443, 2053):
        return False, f"Port {port} is reserved by system daemons (SSH/Web/Nginx/Panel)."

    # 2. IPv4 Socket Binding Probe
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as probe_s4:
            probe_s4.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            probe_s4.bind((host if host != "::" else "0.0.0.0", port))
    except OSError as e:
        return False, f"TCP port {port} is already bound by another process: {e.strerror}"

    # 3. IPv6 Socket Binding Probe (for wildcard bindings)
    if host in ("0.0.0.0", "::"):
        try:
            with socket.socket(socket.AF_INET6, socket.SOCK_STREAM) as probe_s6:
                probe_s6.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
                probe_s6.bind(("::", port))
        except OSError as e:
            if e.errno == 98 or "already in use" in str(e).lower():
                return False, f"TCP port {port} (IPv6) is already bound by another process: {e.strerror}"
        except Exception:
            pass

    return True, ""

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
    # Step A: Pre-flight OS Kernel Socket Binding Check
    is_bindable, reason = verify_socket_bindable(payload.port, payload.listen)
    if not is_bindable:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Port collision: {reason}. Choose an available port (e.g. 10000-60000)."
        )

    # Step B: Database Tag and Port Collision Check
    existing = await db.execute(
        select(Inbound).filter((Inbound.port == payload.port) | (Inbound.tag == payload.tag))
    )
    if existing.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Inbound with port {payload.port} or tag '{payload.tag}' already exists in database."
        )

    # Step C: Write Inbound to Database
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

    # Step D: Atomic Sync & Reload Xray Service
    ok, msg = await XrayService.sync_database_to_xray(db)
    if not ok:
        await db.delete(inbound)
        await db.commit()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Xray core validation rejected configuration: {msg}"
        )

    return {"success": True, "id": inbound.id, "message": "Inbound created and synced successfully."}

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
    return {"success": True, "message": "Inbound removed and Xray configuration re-synced."}
