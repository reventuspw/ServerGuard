#!/usr/bin/env python3

import os
import sys
import time
import socket
import logging
import subprocess
import platform
from datetime import datetime
from pathlib import Path
import yaml
from dotenv import load_dotenv

today = datetime.now().date()

SCRIPT_DIR = Path(__file__).parent

with open(SCRIPT_DIR / "config.yml") as f:
    _cfg = yaml.safe_load(f)

PING_INTERVAL: int = _cfg["monitor"]["ping_interval"]
PING_TIMEOUT: int = _cfg["monitor"]["ping_timeout"]
_log_cfg = _cfg["logging"]
LOG_FILE_PATH = SCRIPT_DIR / _log_cfg["log_dir"] / f"{today}.log"

LOG_FILE_PATH.parent.mkdir(parents=True, exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format=_log_cfg["format"],
    datefmt=_log_cfg["datefmt"],
    handlers=[
        logging.FileHandler(LOG_FILE_PATH),
        logging.StreamHandler(sys.stdout),
    ],
)
log = logging.getLogger(__name__)

def load_server_ips() -> tuple[str, str]:
    load_dotenv(SCRIPT_DIR / ".env")
    ip1 = os.getenv("SERVER_1_IP", "").strip('"').strip("'")
    ip2 = os.getenv("SERVER_2_IP", "").strip('"').strip("'")

    if not ip1 or not ip2:
        log.error(".env is missing SERVER_1_IP or SERVER_2_IP")
        sys.exit(1)

    return ip1, ip2

def get_local_ips() -> set[str]:
    ips = set()

    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            s.connect(("8.8.8.8", 80))
            ips.add(s.getsockname()[0])
    except Exception:
        pass

    try:
        for info in socket.getaddrinfo(socket.gethostname(), None):
            if info[0] == socket.AF_INET:
                ips.add(info[4][0])
    except Exception:
        pass

    return ips

def resolve_peer_ip(ip1: str, ip2: str) -> str:
    local_ips = get_local_ips()

    if ip1 in local_ips:
        log.info(f"This machine is SERVER_1 ({ip1}), monitoring SERVER_2 ({ip2})")
        return ip2
    
    if ip2 in local_ips:
        log.info(f"This machine is SERVER_2 ({ip2}), monitoring SERVER_1 ({ip1})")
        return ip1
    
    log.error(f"Neither {ip1} nor {ip2} matches a local interface - check SERVER_1_IP / SERVER_2_IP in .env")
    sys.exit(1)

def ping(ip: str) -> bool:
    cmd = ["ping", "-c", "1", "-W", str(PING_TIMEOUT), ip]
    result = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    return result.returncode == 0

def run(ip: str) -> None:
    log.info(f"Server monitor started - target: {ip}  interval: {PING_INTERVAL}s")
    was_up: bool | None = None

    while True:
        is_up = ping(ip)

        if is_up:
            if was_up is False:
                log.warning(f"SERVER RECOVERED {ip} is reachable again")
            elif was_up is None:
                log.info(f"UP {ip} is reachable")
            else:
                log.info(f"UP {ip}")

        else:
            if was_up is True:
                log.error(f"SERVER DOWN {ip} is not responding")
            elif was_up is None:
                log.warning(f"DOWN {ip} is not reachable at startup")
            else:
                log.error(f"DOWN {ip}")

        was_up = is_up
        time.sleep(PING_INTERVAL)

if __name__ == "__main__":
    ip1, ip2 = load_server_ips()
    peer_ip = resolve_peer_ip(ip1, ip2)

    try:
        run(peer_ip)
    except KeyboardInterrupt:
        log.info("Server monitor stopped by user")
