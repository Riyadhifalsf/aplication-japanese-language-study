"""Deploy this project to a Proxmox LXC using the Proxmox root SSH account.

Set PVE_PASSWORD in the environment before executing this script. The password
is intentionally never stored in the repository or copied to the LXC.
"""

from __future__ import annotations

import os
import argparse
import shlex
import tarfile
import tempfile
from pathlib import Path

import paramiko


PVE_HOST = os.environ.get("PVE_HOST", "192.168.100.10")
PVE_USER = os.environ.get("PVE_USER", "root")
PVE_PASSWORD = os.environ["PVE_PASSWORD"]
LXC_ID = os.environ.get("PVE_LXC_ID", "100")
REMOTE_DIR = "/opt/japanese-study"
ENV_FILE = "/opt/japanese-study.env"
ARCHIVE = "/tmp/japanese-study.tar.gz"
SKIP_PARTS = {
    ".git",
    ".dart_tool",
    ".gradle",
    ".gradle-user-home",
    ".kotlin",
    "build",
    "node_modules",
    ".env",
}


def include_member(member: tarfile.TarInfo) -> tarfile.TarInfo | None:
    if any(part in SKIP_PARTS for part in Path(member.name).parts):
        return None
    return member


def run(client: paramiko.SSHClient, command: str, timeout: int = 600) -> str:
    _, stdout, stderr = client.exec_command(command, timeout=timeout)
    output = stdout.read().decode(errors="replace")
    error = stderr.read().decode(errors="replace")
    if stdout.channel.recv_exit_status() != 0:
        raise RuntimeError(f"Command failed: {command}\n{output}\n{error}")
    return output


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--set-temporary-password",
        action="store_true",
        help="Set PostgreSQL and admin passwords from DEPLOYMENT_PASSWORD.",
    )
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    with tempfile.NamedTemporaryFile(suffix=".tar.gz", delete=False) as temp:
        archive_path = Path(temp.name)
    try:
        with tarfile.open(archive_path, "w:gz") as archive:
            archive.add(root, arcname="japanese-study", filter=include_member)

        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        client.connect(PVE_HOST, username=PVE_USER, password=PVE_PASSWORD, timeout=20)
        try:
            if args.set_temporary_password:
                deployment_password = os.environ["DEPLOYMENT_PASSWORD"]
                env_contents = (
                    "WEB_PORT=8081\n"
                    f"POSTGRES_PASSWORD={deployment_password}\n"
                    f"ADMIN_TOKEN={deployment_password}\n"
                    "OPENAI_API_KEY=\n"
                    "OPENAI_MODEL=gpt-5.6\n"
                    "CORS_ORIGIN=http://192.168.100.230:8081\n"
                )
                write_env = (
                    f"umask 077; mkdir -p {REMOTE_DIR}; "
                    f"printf %s {shlex.quote(env_contents)} > {REMOTE_DIR}/.env; "
                    f"cp {REMOTE_DIR}/.env {ENV_FILE}"
                )
                run(client, f"pct exec {LXC_ID} -- sh -lc {shlex.quote(write_env)}")
                sql = f"ALTER USER japanese_study WITH PASSWORD '{deployment_password}';"
                alter_role = (
                    f"docker compose -f {REMOTE_DIR}/docker-compose.yml exec -T db "
                    f"psql -U japanese_study -d japanese_study -c "
                    f"{shlex.quote(sql)}"
                )
                run(client, f"pct exec {LXC_ID} -- sh -lc {shlex.quote(alter_role)}")
                return
            with client.open_sftp() as sftp:
                sftp.put(str(archive_path), ARCHIVE)
            run(client, f"pct push {LXC_ID} {ARCHIVE} {ARCHIVE}")
            run(
                client,
                f"pct exec {LXC_ID} -- sh -lc "
                f"'if [ -f {REMOTE_DIR}/.env ] && [ ! -f {ENV_FILE} ]; then "
                f"cp {REMOTE_DIR}/.env {ENV_FILE}; fi; rm -rf {REMOTE_DIR} && "
                f"mkdir -p /opt && tar -xzf {ARCHIVE} -C /opt && rm -f {ARCHIVE} && "
                f"if [ -f {ENV_FILE} ]; then cp {ENV_FILE} {REMOTE_DIR}/.env; fi'",
            )
            run(client, f"rm -f {ARCHIVE}")
            run(
                client,
                f"pct exec {LXC_ID} -- sh -lc "
                f"'cd {REMOTE_DIR} && if [ ! -f .env ]; then umask 077; "
                f"POSTGRES_PASSWORD=$(openssl rand -hex 32); ADMIN_TOKEN=$(openssl rand -hex 32); "
                f"printf \"WEB_PORT=8081\\nPOSTGRES_PASSWORD=%s\\nADMIN_TOKEN=%s\\nOPENAI_API_KEY=\\nOPENAI_MODEL=gpt-5.6\\nCORS_ORIGIN=http://192.168.100.230:8081\\n\" "
                f"\"$POSTGRES_PASSWORD\" \"$ADMIN_TOKEN\" > .env; cp .env {ENV_FILE}; fi; "
                f"nohup sh -c \"docker compose up -d --build\" "
                f"> /var/log/japanese-study-deploy.log 2>&1 &'",
            )
        finally:
            client.close()
    finally:
        archive_path.unlink(missing_ok=True)


if __name__ == "__main__":
    main()
