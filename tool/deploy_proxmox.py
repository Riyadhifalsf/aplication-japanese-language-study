"""Deploy the unified backend/ (API + Postgres + nginx proxy) to a Proxmox LXC.

Setup:
  put PVE_HOST/PVE_USER/PVE_LXC_ID in the environment (defaults below).
  set PVE_PASSWORD. Password is never stored in the repo.

Examples:
  # Create .env with random secrets and boot everything:
  python tool/deploy_proxmox.py --init-env

  # Rebuild/restart from the current backend/ state (keeps existing .env):
  python tool/deploy_proxmox.py
"""

from __future__ import annotations

import os
import argparse
import shlex
import secrets
import tarfile
import tempfile
from pathlib import Path

import paramiko


PVE_HOST = os.environ.get("PVE_HOST", "192.168.100.10")
PVE_USER = os.environ.get("PVE_USER", "root")
PVE_PASSWORD = os.environ["PVE_PASSWORD"]
LXC_ID = os.environ.get("PVE_LXC_ID", "200")
LXC_IP = os.environ.get("PVE_LXC_IP", "192.168.100.11")
SRC_DIR = "backend"
REMOTE_DIR = "/opt/japan-api"
ENV_FILE = "/opt/japan-api.env"
ARCHIVE = "/tmp/japan-api.tar.gz"


def run(client: paramiko.SSHClient, command: str, timeout: int = 900) -> str:
    _, stdout, stderr = client.exec_command(command, timeout=timeout)
    output = stdout.read().decode(errors="replace")
    error = stderr.read().decode(errors="replace")
    if stdout.channel.recv_exit_status() != 0:
        raise RuntimeError(f"Command failed: {command}\n{output}\n{error}")
    return output


def write_env() -> str:
    return (
        f"POSTGRES_PASSWORD={secrets.token_urlsafe(32)}\n"
        f"JWT_SECRET={secrets.token_urlsafe(48)}\n"
        f"ADMIN_TOKEN={secrets.token_urlsafe(40)}\n"
        f"ADMIN_EMAIL=admin@example.com\n"
        f"ADMIN_PASSWORD={secrets.token_urlsafe(20)}\n"
        f"TLS_IP={LXC_IP}\n"
        f"CORS_ORIGIN=*\n"
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--init-env",
        action="store_true",
        help="Create a fresh .env with random secrets (keeps existing DB volume).",
    )
    args = parser.parse_args()

    root = Path(__file__).resolve().parents[1]
    backend = root / SRC_DIR
    with tempfile.NamedTemporaryFile(suffix=".tar.gz", delete=False) as temp:
        archive_path = Path(temp.name)

    def include_member(member: tarfile.TarInfo) -> tarfile.TarInfo | None:
        name = Path(member.name)
        if name.name in {".env", ".env.example"} or any(
            part in {".git", "__pycache__"} for part in name.parts
        ):
            return None
        return member

    try:
        with tarfile.open(archive_path, "w:gz") as archive:
            archive.add(backend, arcname="japan-api", filter=include_member)

        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        client.connect(PVE_HOST, username=PVE_USER, password=PVE_PASSWORD, timeout=20)
        try:
            env_contents = write_env() if args.init_env else None
            if env_contents is not None:
                cmd = (
                    f"umask 077; mkdir -p {REMOTE_DIR}; "
                    f"printf %s {shlex.quote(env_contents)} > {REMOTE_DIR}/.env; "
                    f"cp {REMOTE_DIR}/.env {ENV_FILE}"
                )
                run(client, f"pct exec {LXC_ID} -- sh -lc {shlex.quote(cmd)}")

            with client.open_sftp() as sftp:
                sftp.put(str(archive_path), ARCHIVE)
            run(client, f"pct push {LXC_ID} {ARCHIVE} {ARCHIVE}")
            run(
                client,
                f"pct exec {LXC_ID} -- sh -lc "
                f"'if [ -f {ENV_FILE} ]; then cp {ENV_FILE} /tmp/japan-api.env.tmp; fi; "
                f"rm -rf {REMOTE_DIR} && mkdir -p {REMOTE_DIR} && "
                f"tar -xzf {ARCHIVE} -C /opt && rm -f {ARCHIVE} && "
                f"cd {REMOTE_DIR} && "
                f"if [ -f /tmp/japan-api.env.tmp ]; then mv /tmp/japan-api.env.tmp .env; cp .env {ENV_FILE}; fi; "
                f"if [ ! -f .env ]; then umask 077; "
                f"cat > .env <<'ENVEOF'\n"
                f"POSTGRES_PASSWORD=$(openssl rand -hex 32)\n"
                f"JWT_SECRET=$(openssl rand -hex 48)\n"
                f"ADMIN_TOKEN=$(openssl rand -hex 40)\n"
                f"ADMIN_EMAIL=admin@example.com\n"
                f"ADMIN_PASSWORD=$(openssl rand -hex 20)\n"
                f"TLS_IP={LXC_IP}\n"
                f"CORS_ORIGIN=*\n"
                f"ENVEOF\n"
                f"cp .env {ENV_FILE}; fi'",
            )
            run(client, f"rm -f {ARCHIVE}")
            run(
                client,
                f"pct exec {LXC_ID} -- sh -lc "
                f"'cd {REMOTE_DIR} && cp .env {ENV_FILE} && "
                f"nohup sh -c \"docker compose up -d --build\" "
                f"> /var/log/japan-api-deploy.log 2>&1 &'",
            )
            print(
                "Deploy launched at "
                f"https://{LXC_IP}/api/health (self-signed). "
                f"Watch: /var/log/japan-api-deploy.log on LXC {LXC_ID}."
            )
        finally:
            client.close()
    finally:
        archive_path.unlink(missing_ok=True)


if __name__ == "__main__":
    main()