import subprocess
import re
from datetime import datetime
from typing import Tuple, List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.db.models import SSHTunnelUser

TUNNEL_SHELL = "/usr/local/bin/mehboobxt-tunnel-shell"
TUNNEL_GROUP = "mehboobxt_tunnel"

class SSHService:
    @staticmethod
    def validate_username(username: str) -> bool:
        return bool(re.match(r"^[a-zA-Z0-9_]{3,32}$", username))

    @staticmethod
    def create_system_user(username: str, password: str, expiry_date: datetime | None = None) -> Tuple[bool, str]:
        if not SSHService.validate_username(username):
            return False, "Invalid username format. Must be 3-32 alphanumeric characters."

        # useradd with no home directory creation, assigned to tunnel shell & group
        cmd = [
            "useradd",
            "-M",
            "-g", TUNNEL_GROUP,
            "-s", TUNNEL_SHELL,
            username
        ]
        try:
            subprocess.run(cmd, check=True, capture_output=True, text=True)
        except subprocess.CalledProcessError as e:
            return False, f"Failed to create Linux system user: {e.stderr.strip()}"

        # Safe password setting via stdin
        try:
            p = subprocess.Popen(["chpasswd"], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            stdout, stderr = p.communicate(input=f"{username}:{password}\n")
            if p.returncode != 0:
                return False, f"Failed to set system password: {stderr.strip()}"
        except Exception as e:
            return False, str(e)

        # Set account expiry if specified
        if expiry_date:
            exp_str = expiry_date.strftime("%Y-%m-%d")
            subprocess.run(["chage", "-E", exp_str, username], capture_output=True)

        return True, f"System user {username} provisioned successfully."

    @staticmethod
    def update_system_password(username: str, new_password: str) -> Tuple[bool, str]:
        if not SSHService.validate_username(username):
            return False, "Invalid username."
        try:
            p = subprocess.Popen(["chpasswd"], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            _, stderr = p.communicate(input=f"{username}:{new_password}\n")
            if p.returncode != 0:
                return False, stderr.strip()
            return True, "Password updated successfully."
        except Exception as e:
            return False, str(e)

    @staticmethod
    def toggle_user_lock(username: str, lock: bool) -> Tuple[bool, str]:
        flag = "-L" if lock else "-U"
        try:
            subprocess.run(["usermod", flag, username], check=True, capture_output=True, text=True)
            if lock:
                # Terminate any active sessions immediately
                subprocess.run(["pkill", "-u", username], capture_output=True)
            return True, f"User {username} {'locked' if lock else 'unlocked'}."
        except subprocess.CalledProcessError as e:
            return False, e.stderr.strip()

    @staticmethod
    def delete_system_user(username: str) -> Tuple[bool, str]:
        if not SSHService.validate_username(username):
            return False, "Invalid username."
        subprocess.run(["pkill", "-u", username], capture_output=True)
        try:
            subprocess.run(["userdel", username], check=True, capture_output=True, text=True)
            return True, f"User {username} deleted."
        except subprocess.CalledProcessError as e:
            return False, e.stderr.strip()
