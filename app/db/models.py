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
