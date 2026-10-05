import os
import json
import shutil
import tempfile
import subprocess
from typing import Tuple, Dict, Any
from app.core.config import settings

class XrayEngine:
    @staticmethod
    def test_config(config_dict: Dict[str, Any]) -> Tuple[bool, str]:
        """Validates configuration against Xray binary without modifying production."""
        with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as tf:
            json.dump(config_dict, tf, indent=2)
            temp_path = tf.name

        try:
            cmd = [settings.xray_bin, "test", "-config", temp_path]
            proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=10)
            if proc.returncode == 0:
                return True, "Configuration validated successfully."
            return False, f"Xray test failed:\n{proc.stderr.strip() or proc.stdout.strip()}"
        except Exception as e:
            return False, f"Execution exception: {str(e)}"
        finally:
            if os.path.exists(temp_path):
                os.remove(temp_path)

    @staticmethod
    def apply_config(config_dict: Dict[str, Any]) -> Tuple[bool, str]:
        """Validates atomically, creates a backup, writes config, and reloads service."""
        is_valid, msg = XrayEngine.test_config(config_dict)
        if not is_valid:
            return False, msg

        # Backup current working configuration
        backup_path = f"{settings.xray_config}.bak"
        if os.path.exists(settings.xray_config):
            shutil.copy2(settings.xray_config, backup_path)

        # Atomic write
        temp_target = f"{settings.xray_config}.tmp"
        with open(temp_target, "w", encoding="utf-8") as f:
            json.dump(config_dict, f, indent=2)
        os.replace(temp_target, settings.xray_config)

        # Restart service
        restart_ok, restart_msg = XrayEngine.restart_service()
        if not restart_ok:
            # Rollback
            if os.path.exists(backup_path):
                shutil.copy2(backup_path, settings.xray_config)
                XrayEngine.restart_service()
            return False, f"Service restart failed, rolled back to previous config: {restart_msg}"

        return True, "Configuration applied and Xray reloaded successfully."

    @staticmethod
    def restart_service() -> Tuple[bool, str]:
        try:
            subprocess.run(["systemctl", "restart", "mehboobxt-xray.service"], check=True, capture_output=True, text=True)
            return True, "mehboobxt-xray restarted."
        except subprocess.CalledProcessError as e:
            return False, e.stderr.strip()

    @staticmethod
    def get_status() -> Dict[str, Any]:
        try:
            res = subprocess.run(["systemctl", "is-active", "mehboobxt-xray.service"], capture_output=True, text=True)
            is_active = (res.stdout.strip() == "active")
        except Exception:
            is_active = False

        return {
            "service": "mehboobxt-xray",
            "is_active": is_active,
            "binary_path": settings.xray_bin,
            "config_path": settings.xray_config
        }

    @staticmethod
    def generate_reality_keypair() -> Dict[str, str]:
        """Generates an X25519 Reality keypair using Xray binary."""
        try:
            proc = subprocess.run([settings.xray_bin, "x25519"], capture_output=True, text=True, check=True)
            lines = proc.stdout.strip().splitlines()
            priv, pub = "", ""
            for line in lines:
                if "PrivateKey:" in line or "Private key:" in line:
                    priv = line.split(":", 1)[1].strip()
                elif "PublicKey:" in line or "Public key:" in line:
                    pub = line.split(":", 1)[1].strip()
            return {"private_key": priv, "public_key": pub}
        except Exception as e:
            return {"error": str(e), "private_key": "", "public_key": ""}
