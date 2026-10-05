from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional

class SSHTunnelUserCreate(BaseModel):
    username: str = Field(..., min_length=3, max_length=32, pattern=r"^[a-zA-Z0-9_]+$")
    password: str = Field(..., min_length=4, max_length=64)
    expiry_date: Optional[datetime] = None
    max_connections: int = Field(default=2, ge=1, le=50)
    is_active: bool = True

class SSHTunnelUserUpdate(BaseModel):
    password: Optional[str] = Field(None, min_length=4, max_length=64)
    expiry_date: Optional[datetime] = None
    max_connections: Optional[int] = Field(None, ge=1, le=50)
    is_active: Optional[bool] = None

class SSHTunnelUserResponse(BaseModel):
    id: int
    username: str
    expiry_date: Optional[datetime]
    max_connections: int
    is_active: bool
    up_bytes: int
    down_bytes: int
    created_at: datetime
