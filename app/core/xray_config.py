import json
from typing import List, Dict, Any
from app.db.models import Inbound, Client

def build_xray_config(inbounds: List[Inbound], clients_map: Dict[int, List[Client]]) -> Dict[str, Any]:
    """Builds standard, verified Xray-core JSON structure."""
    xray_inbounds = []

    for ib in inbounds:
        if not ib.is_enabled:
            continue

        raw_stream = json.loads(ib.stream_settings_json) if ib.stream_settings_json else {}
        network = raw_stream.get("network", "tcp")
        security = raw_stream.get("security", "none")

        ib_clients = clients_map.get(ib.id, [])
        client_list = []

        if ib.protocol in ("vless", "vmess"):
            for cl in ib_clients:
                if cl.is_enabled:
                    client_entry = {
                        "id": cl.uuid,
                        "email": cl.email
                    }
                    if ib.protocol == "vless" and cl.flow:
                        client_entry["flow"] = cl.flow
                    elif ib.protocol == "vmess":
                        client_entry["alterId"] = 0
                    client_list.append(client_entry)
            
            inbound_settings = {
                "clients": client_list,
                "decryption": "none" if ib.protocol == "vless" else None
            }
            if inbound_settings["decryption"] is None:
                del inbound_settings["decryption"]

        elif ib.protocol == "trojan":
            for cl in ib_clients:
                if cl.is_enabled:
                    client_list.append({
                        "password": cl.uuid,
                        "email": cl.email
                    })
            inbound_settings = {"clients": client_list}
        else:
            inbound_settings = {}

        # Stream Settings
        stream_dict = {"network": network, "security": security}

        if security == "reality":
            rs = raw_stream.get("reality_settings", {})
            stream_dict["realitySettings"] = {
                "show": False,
                "dest": rs.get("dest", "www.microsoft.com:443"),
                "xver": 0,
                "serverNames": rs.get("server_names", ["www.microsoft.com"]),
                "privateKey": rs.get("private_key", ""),
                "shortIds": rs.get("short_ids", [""]),
                "fingerprint": rs.get("fingerprint", "chrome"),
                "spiderX": rs.get("spider_x", "/")
            }
        elif security == "tls":
            ts = raw_stream.get("tls_settings", {})
            stream_dict["tlsSettings"] = {
                "serverName": ts.get("server_name", ""),
                "certificates": []
            }

        # Network Specifics
        if network == "ws":
            stream_dict["wsSettings"] = {
                "path": raw_stream.get("ws_path", "/ws"),
                "headers": {}
            }
        elif network == "grpc":
            stream_dict["grpcSettings"] = {
                "serviceName": raw_stream.get("grpc_service_name", "grpc")
            }

        # Sniffing
        sniffing_dict = {
            "enabled": True,
            "destOverride": ["http", "tls", "quic"],
            "metadataOnly": False
        }

        xray_inbound = {
            "tag": ib.tag,
            "port": ib.port,
            "listen": ib.listen,
            "protocol": ib.protocol,
            "settings": inbound_settings,
            "streamSettings": stream_dict,
            "sniffing": sniffing_dict
        }
        xray_inbounds.append(xray_inbound)

    return {
        "log": {
            "access": "/opt/mehboobxt/logs/xray_access.log",
            "error": "/opt/mehboobxt/logs/xray_error.log",
            "loglevel": "warning"
        },
        "api": {
            "tag": "api",
            "services": ["HandlerService", "StatsService"]
        },
        "inbounds": xray_inbounds,
        "outbounds": [
            {"protocol": "freedom", "tag": "direct"},
            {"protocol": "blackhole", "tag": "blocked"}
        ],
        "routing": {
            "domainStrategy": "AsIs",
            "rules": [
                {"type": "field", "inboundTag": ["api"], "outboundTag": "api"}
            ]
        }
    }
