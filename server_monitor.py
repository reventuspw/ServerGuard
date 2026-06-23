#!/usr/bin/env python3
import os
import sys
import time
import logging
import subprocess
import platform
from datetime import datetime
from pathlib import Path
from dotenv import load_dotenv

SCRIPT_DIR = Path(__file__).parent
LOG_FILE = SCRIPT_DIR / "server_monitor.log"
PING_INTERVAL = 30  # seconds between pings
PING_TIMEOUT = 5    # seconds to wait for ping response

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler(sys.stdout),
    ],
)
log = logging.getLogger(__name__)


def load_remote_ip() -> str:
    load_dotenv(SCRIPT_DIR / ".env")
    ip = os.getenv("REMOTE_IP")
    if not ip:
        log.error(".env is missing REMOTE_IP")
        sys.exit(1)
    return ip.strip('"').strip("'")

def ping(ip: str) -> bool:
    if platform.system() == "Windows":
        cmd = ["ping", "-n", "1", "-w", str(PING_TIMEOUT * 1000), ip]
    else:
        cmd = ["ping", "-c", "1", "-W", str(PING_TIMEOUT), ip]

    result = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return result.returncode == 0


def run(ip: str) -> None:
    log.info(f"Server monitor started — target: {ip}  interval: {PING_INTERVAL}s")
    was_up: bool | None = None

    while True:
        is_up = ping(ip)

        if is_up:
            if was_up is False:
                log.warning(f"SERVER RECOVERED  {ip} is reachable again")
            elif was_up is None:
                log.info(f"UP  {ip} is reachable")
            else:
                log.info(f"UP  {ip}")
        else:
            if was_up is True:
                log.error(f"SERVER DOWN  {ip} is not responding")
            elif was_up is None:
                log.warning(f"DOWN  {ip} is not reachable at startup")
            else:
                log.error(f"DOWN  {ip}")

        was_up = is_up
        time.sleep(PING_INTERVAL)


if __name__ == "__main__":
    ip = load_remote_ip()
    try:
        run(ip)
    except KeyboardInterrupt:
        log.info("Server monitor stopped by user")
