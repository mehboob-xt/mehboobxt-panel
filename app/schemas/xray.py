from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any

class RealitySettings(BaseModel):
    dest: str = "www.microsoft.com:443"
    server_names: List[str] = ["www.microsoft.com"]
    private_key: str
    public_key: str
    short_ids: List[str] = [""]
    fingerprint: str = "chrome"
    spider_x: str = "/"

class StreamSettings(BaseModel):
    network: str = "tcp"  # tcp, ws, grpc, xhttp
    security: str = "none"  # none, tls, reality
    reality_settings: Optional[RealitySettings] = None
    ws_path: Optional[str] = "/ws"
    grpc_service_name: Optional[str] = None
    tls_server_name: Optional[str] = None

class InboundCreate(BaseModel):
    tag: str = Field(..., min_length=2, max_length=64)
    protocol: str = Field(..., pattern="^(vless|vmess|trojan)$")
    port: int = Field(..., ge=1, le=65535)
    listen: str = "0.0.0.0"
    stream: StreamSettings = StreamSettings()
    sniffing_enabled: bool = True
    total_limit_bytes: int = 0
    expiry_timestamp: int = 0
    is_enabled: bool = True

class InboundUpdate(BaseModel):
    listen: Optional[str] = None
    stream: Optional[StreamSettings] = None
    sniffing_enabled: Optional[bool] = None
    total_limit_bytes: Optional[int] = None
    expiry_timestamp: Optional[int] = None
    is_enabled: Optional[bool] = None

class InboundResponse(BaseModel):
    id: int
    tag: str
    protocol: str
    port: int
    listen: str
    stream: StreamSettings
    sniffing_enabled: bool
    up_bytes: int
    down_bytes: int
    total_limit_bytes: int
    expiry_timestamp: int
    is_enabled: bool
    client_count: int = 0

class ClientCreate(BaseModel):
    inbound_id: int
    email: str = Field(..., min_length=3, max_length=128)
    uuid: Optional[str] = None
    flow: Optional[str] = ""
    total_limit_bytes: int = 0
    expiry_timestamp: int = 0
    is_enabled: bool = True

class ClientUpdate(BaseModel):
    flow: Optional[str] = None
    total_limit_bytes: Optional[int] = None
    expiry_timestamp: Optional[int] = None
    is_enabled: Optional[bool] = None

class ClientResponse(BaseModel):
    id: int
    inbound_id: Optional[int]
    email: str
    uuid: str
    flow: Optional[str]
    up_bytes: int
    down_bytes: int
    total_limit_bytes: int
    expiry_timestamp: int
    is_enabled: bool
    client_type: str
    share_link: Optional[str] = None
