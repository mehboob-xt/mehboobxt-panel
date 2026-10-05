import urllib.parse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import Dict, Any, List
from app.db.models import Inbound, Client
from app.core.xray_config import build_xray_config
from app.core.xray_engine import XrayEngine

class XrayService:
    @staticmethod
    async def sync_database_to_xray(db: AsyncSession) -> tuple[bool, str]:
        """Loads all inbounds & clients, builds config, and applies it safely."""
        inbounds_res = await db.execute(select(Inbound))
        inbounds = list(inbounds_res.scalars().all())

        clients_res = await db.execute(select(Client).filter_by(client_type="xray"))
        all_clients = list(clients_res.scalars().all())

        clients_map: Dict[int, List[Client]] = {}
        for cl in all_clients:
            if cl.inbound_id not in clients_map:
                clients_map[cl.inbound_id] = []
            clients_map[cl.inbound_id].append(cl)

        cfg_dict = build_xray_config(inbounds, clients_map)
        return XrayEngine.apply_config(cfg_dict)

    @staticmethod
    def generate_share_link(client: Client, inbound: Inbound, public_ip: str) -> str:
        """Generates standard vless://, vmess://, or trojan:// URI links."""
        try:
            import json
            raw_stream = json.loads(inbound.stream_settings_json) if inbound.stream_settings_json else {}
            net = raw_stream.get("network", "tcp")
            sec = raw_stream.get("security", "none")
            remark = f"{inbound.tag}-{client.email}"

            if inbound.protocol == "vless":
                params = {"type": net, "security": sec}
                if sec == "reality":
                    rs = raw_stream.get("reality_settings", {})
                    params["pbk"] = rs.get("public_key", "")
                    params["fp"] = rs.get("fingerprint", "chrome")
                    sns = rs.get("server_names", [""])
                    params["sni"] = sns[0] if sns else ""
                    sids = rs.get("short_ids", [""])
                    params["sid"] = sids[0] if sids else ""
                    params["spx"] = rs.get("spider_x", "/")
                if client.flow:
                    params["flow"] = client.flow
                query = urllib.parse.urlencode(params)
                return f"vless://{client.uuid}@{public_ip}:{inbound.port}?{query}#{urllib.parse.quote(remark)}"

            elif inbound.protocol == "trojan":
                params = {"type": net, "security": sec}
                query = urllib.parse.urlencode(params)
                return f"trojan://{client.uuid}@{public_ip}:{inbound.port}?{query}#{urllib.parse.quote(remark)}"

            return "protocol_unsupported_for_link"
        except Exception:
            return ""
