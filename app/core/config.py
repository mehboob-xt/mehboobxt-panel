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
