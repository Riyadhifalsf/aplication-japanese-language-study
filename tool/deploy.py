"""Cross-platform deploy & repo tooling, paramiko-based (no PuTTY required).

Runs on Windows/macOS/Linux with Python 3.8+ plus the `paramiko` package
(see tool/requirements.txt). Two target kinds are supported:

  * lxc - Proxmox LXC: archive is uploaded to the PVE host, pushed into the
          container with `pct push`, commands executed via `pct exec`.
  * ssh - generic Linux host with Docker: archive is uploaded straight to the
          remote, commands executed directly over SSH.

Configuration comes from env vars (DEPLOY_*) with CLI overrides on top.
Secrets come from the environment only and are never stored in the repo.

Examples:
  python tool/deploy.py deploy --init-env              # Proxmox LXC 200
  python tool/deploy.py deploy --target ssh --init-env # generic Docker VPS
  python tool/deploy.py check                          # preflight checks
  python tool/deploy.py push "commit message"          # add + commit + push
"""

from __future__ import annotations

import argparse
import base64
import os
import posixpath
import secrets
import shlex
import ssl
import subprocess
import tarfile
import tempfile
import time
import urllib.request
from pathlib import Path

import paramiko


def build_config(args: argparse.Namespace) -> dict:
    hostname = os.environ.get("DEPLOY_HOSTNAME") or os.environ.get("DEPLOY_LXC_IP") or "192.168.100.11"
    return {
        "host": args.host or os.environ.get("DEPLOY_HOST", "192.168.100.10"),
        "user": args.user or os.environ.get("DEPLOY_USER", "root"),
        "password": os.environ.get("DEPLOY_PASSWORD", ""),
        "key": args.key or os.environ.get("DEPLOY_KEY", ""),
        "passphrase": os.environ.get("DEPLOY_KEY_PASSPHRASE", ""),
        "port": args.port or int(os.environ.get("DEPLOY_PORT", "22")),
        "target": args.target or os.environ.get("DEPLOY_TARGET", "lxc"),
        "lxc_id": args.lxc_id or os.environ.get("DEPLOY_LXC_ID", "200"),
        "hostname": args.hostname or hostname,
        "remote_dir": args.remote_dir or os.environ.get("DEPLOY_REMOTE_DIR", "/opt/japan-api"),
        "admin_email": args.admin_email or os.environ.get("DEPLOY_ADMIN_EMAIL", "admin@example.com"),
    }


def connect(cfg: dict) -> paramiko.SSHClient:
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    kw = {"timeout": 25}
    if cfg["key"]:
        kw["key_filename"] = cfg["key"]
        if cfg["passphrase"]:
            kw["passphrase"] = cfg["passphrase"]
    else:
        kw["password"] = cfg["password"]
    client.connect(cfg["host"], port=cfg["port"], username=cfg["user"], **kw)
    return client


def exec_raw(client: paramiko.SSHClient, command: str, timeout: int = 1800) -> tuple[int, str]:
    _, stdout, stderr = client.exec_command(command, timeout=timeout)
    out = stdout.read().decode(errors="replace")
    err = stderr.read().decode(errors="replace")
    return stdout.channel.recv_exit_status(), (out + err).strip()


def put(client: paramiko.SSHClient, local: Path, remote: str) -> None:
    with client.open_sftp() as sftp:
        sftp.put(str(local), remote)


class Target:
    def __init__(self, client: paramiko.SSHClient, cfg: dict):
        self.client = client
        self.cfg = cfg

    def put_file(self, local: Path, remote: str) -> tuple[int, str]:
        raise NotImplementedError

    def run(self, command: str, timeout: int = 1800) -> tuple[int, str]:
        raise NotImplementedError


class LxcTarget(Target):
    PCT = "/usr/sbin/pct"

    def put_file(self, local: Path, remote: str) -> tuple[int, str]:
        host_tmp = f"/tmp/{local.name}"
        put(self.client, local, host_tmp)
        return self.run(f"{self.PCT} push {self.cfg['lxc_id']} {host_tmp} {remote} && rm -f {host_tmp}")

    def run(self, command: str, timeout: int = 1800) -> tuple[int, str]:
        wrapped = f"{self.PCT} exec {self.cfg['lxc_id']} -- sh -lc {shlex.quote(command)}"
        return exec_raw(self.client, wrapped, timeout)


class SshTarget(Target):
    def put_file(self, local: Path, remote: str) -> tuple[int, str]:
        parent = posixpath.dirname(remote)
        status, out = self.run(f"mkdir -p {shlex.quote(parent)}")
        if status:
            return status, out
        put(self.client, local, remote)
        return 0, f"uploaded {local.name} -> {remote}"

    def run(self, command: str, timeout: int = 1800) -> tuple[int, str]:
        return exec_raw(self.client, command, timeout)


def run_script(target: Target, script: str, timeout: int = 2400, verbose: bool = False) -> None:
    b64 = base64.b64encode(script.encode()).decode()
    helper = "echo {0} | base64 -d > {1}\nbash {1}\nrm -f {1}\n".format(
        shlex.quote(b64), "/tmp/ja_op.sh"
    )
    local = Path(tempfile.mkstemp(suffix=".sh")[1])
    try:
        local.write_text(helper, encoding="utf-8")
        status, out = target.put_file(local, "/tmp/ja_op.sh")
        if status:
            raise RuntimeError(f"upload failed ({status}): {out}")
        status, out = target.run("bash /tmp/ja_op.sh", timeout=timeout)
        if verbose and out:
            print(out)
        if status:
            raise RuntimeError(f"remote script failed ({status}): {out}")
    finally:
        local.unlink(missing_ok=True)


def env_contents(cfg: dict) -> str:
    values = {
        "POSTGRES_PASSWORD": secrets.token_urlsafe(32),
        "JWT_SECRET": secrets.token_urlsafe(48),
        "ADMIN_TOKEN": secrets.token_urlsafe(40),
        "ADMIN_EMAIL": cfg["admin_email"],
        "ADMIN_PASSWORD": secrets.token_urlsafe(20),
        "TLS_IP": cfg["hostname"],
        "CORS_ORIGIN": "*",
    }
    return "".join(f"{k}={v}\n" for k, v in values.items())


def env_script(cfg: dict) -> str:
    d = shlex.quote(cfg["remote_dir"])
    return (
        "umask 077\n"
        f"mkdir -p {d}\n"
        f"cat > {d}/.env <<'ENVEOF'\n"
        f"{env_contents(cfg)}ENVEOF\n"
        "echo wrote .env\n"
    )


def deploy_script(cfg: dict) -> str:
    d = cfg["remote_dir"]
    parent, _ = posixpath.split(d.rstrip("/"))
    env_backup = f"{d}.env"
    return f"""set -e
D={shlex.quote(d)}
P={shlex.quote(parent)}
EB={shlex.quote(env_backup)}
if [ -f "$D/.env" ]; then cp "$D/.env" "$EB"; fi
rm -rf "$D"
mkdir -p "$P"
tar -xzf /tmp/japan-api.tar.gz -C "$P"
if [ -f "$EB" ]; then mv "$EB" "$D/.env"; fi
if [ ! -f "$D/.env" ]; then
  umask 077
  cat > "$D/.env" <<'ENVGEN'
POSTGRES_PASSWORD=$(openssl rand -hex 32)
JWT_SECRET=$(openssl rand -hex 48)
ADMIN_TOKEN=$(openssl rand -hex 40)
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=$(openssl rand -hex 20)
TLS_IP={cfg['hostname']}
CORS_ORIGIN=*
ENVGEN
fi
cp "$D/.env" "$EB"
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  COMPOSE="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE="docker-compose"
else
  echo "no docker compose on target" >&2
  exit 1
fi
cd "$D"
nohup $COMPOSE up -d --build > /var/log/japan-api-deploy.log 2>&1 &
echo boot launched
"""


def build_archive(root: Path) -> Path:
    backend = root / "backend"
    if not backend.is_dir():
        raise SystemExit(f"missing backend dir: {backend}")
    _, path = tempfile.mkstemp(suffix=".tar.gz")
    os.close(_)
    archive = Path(path)

    def member_filter(member: tarfile.TarInfo) -> tarfile.TarInfo | None:
        name = Path(member.name)
        if name.name in {".env", ".env.example"}:
            return None
        if any(part in {".git", "__pycache__", "node_modules"} for part in name.parts):
            return None
        return member

    with tarfile.open(archive, "w:gz") as tar:
        tar.add(backend, arcname="japan-api", filter=member_filter)
    return archive


def wait_health(url: str, timeout: float = 240, interval: float = 6) -> bool:
    context = ssl.create_default_context()
    context.check_hostname = False
    context.verify_mode = ssl.CERT_NONE
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            with urllib.request.urlopen(url, context=context, timeout=10) as resp:
                if resp.status == 200:
                    return True
        except Exception:
            pass
        time.sleep(interval)
    return False


def cmd_deploy(args: argparse.Namespace) -> None:
    cfg = build_config(args)
    root = Path(__file__).resolve().parents[1]
    archive = build_archive(root)
    if args.dry_run:
        if args.init_env:
            print(env_script(cfg))
        print(deploy_script(cfg))
        print(f"archive: {archive} ({archive.stat().st_size} bytes)")
        return
    client = connect(cfg)
    try:
        target = LxcTarget(client, cfg) if cfg["target"] == "lxc" else SshTarget(client, cfg)
        print(f"target={cfg['target']} host={cfg['host']} dir={cfg['remote_dir']}")
        if args.init_env:
            run_script(target, env_script(cfg), verbose=args.verbose)
        status, out = target.put_file(archive, "/tmp/japan-api.tar.gz")
        if status:
            raise RuntimeError(f"archive upload failed ({status}): {out}")
        run_script(target, deploy_script(cfg), verbose=args.verbose)
        url = f"https://{cfg['hostname']}/api/health"
        if args.skip_health:
            print(f"boot launched. health check skipped: {url}")
        elif wait_health(url):
            print(f"healthy: {url}")
        else:
            print(f"boot launched but health not ready yet: {url} (check /var/log/japan-api-deploy.log)")
    finally:
        client.close()
        archive.unlink(missing_ok=True)


def cmd_check(args: argparse.Namespace) -> None:
    cfg = build_config(args)
    client = connect(cfg)
    probe = "echo host=$(hostname); command -v docker || true; docker --version 2>/dev/null || true; docker compose version 2>/dev/null || docker-compose --version 2>/dev/null || true; df -h / | tail -1; free -m 2>/dev/null | head -2"
    try:
        if cfg["target"] == "lxc":
            status, out = exec_raw(client, "/usr/sbin/pct list", timeout=60)
            print(out)
            print(exec_raw(client, f"/usr/sbin/pct config {cfg['lxc_id']}", timeout=60)[1])
        target = LxcTarget(client, cfg) if cfg["target"] == "lxc" else SshTarget(client, cfg)
        status, out = target.run(probe, timeout=120)
        print(out)
        if status:
            raise RuntimeError(f"probe failed ({status})")
    finally:
        client.close()


def cmd_push(args: argparse.Namespace) -> None:
    def git(*parts: str) -> tuple[int, str]:
        result = subprocess.run(["git", *parts], text=True, capture_output=True)
        return result.returncode, (result.stdout + result.stderr).strip()

    code, branch = git("rev-parse", "--abbrev-ref", "HEAD")
    if code:
        raise SystemExit("not a git repository")
    message = " ".join(args.message) or "deploy: update"
    code, out = git("add", "-A")
    print(out)
    code, out = git("commit", "-m", message)
    print(out)
    if code and "nothing to commit" not in out:
        raise SystemExit(f"commit failed ({code})")
    code, out = git("push", "origin", branch)
    print(out)
    if code:
        raise SystemExit(f"push failed ({code})")
    print(f"pushed {branch} @ origin")


def build_parser() -> argparse.ArgumentParser:
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument("--host", help="DEPLOY_HOST (default: 192.168.100.10)")
    common.add_argument("--user", help="DEPLOY_USER (default: root)")
    common.add_argument("--port", type=int, help="DEPLOY_PORT (default: 22)")
    common.add_argument("--key", help="DEPLOY_KEY path to OpenSSH private key")
    common.add_argument("--target", choices=["lxc", "ssh"], help="DEPLOY_TARGET (default: lxc)")
    common.add_argument("--lxc-id", help="DEPLOY_LXC_ID (default: 200)")
    common.add_argument("--hostname", help="DEPLOY_HOSTNAME for proxy/health URL")
    common.add_argument("--remote-dir", help="DEPLOY_REMOTE_DIR (default: /opt/japan-api)")
    common.add_argument("--admin-email", help="DEPLOY_ADMIN_EMAIL for generated admin account")

    parser = argparse.ArgumentParser(prog="tool/deploy.py", description="Cross-platform deploy tooling for Japanese Study.")
    sub = parser.add_subparsers(dest="command", required=True)

    deploy = sub.add_parser("deploy", parents=[common], help="upload backend/ and boot it on the target")
    deploy.add_argument("--init-env", action="store_true", help="write a fresh .env with random secrets")
    deploy.add_argument("--skip-health", action="store_true", help="do not poll /api/health")
    deploy.add_argument("--dry-run", action="store_true", help="only print the commands/archive info")
    deploy.add_argument("--verbose", action="store_true", help="show remote output")
    deploy.set_defaults(func=cmd_deploy)

    check = sub.add_parser("check", parents=[common], help="preflight the target (connectivity, docker, disk)")
    check.set_defaults(func=cmd_check)

    push = sub.add_parser("push", help="git add -A, commit and push current branch")
    push.add_argument("message", nargs="*", help="commit message")
    push.set_defaults(func=cmd_push)

    return parser


def main() -> None:
    try:
        import paramiko  # noqa: F401
    except ImportError as exc:
        raise SystemExit("paramiko is required: pip install -r tool/requirements.txt") from exc
    args = build_parser().parse_args()
    args.func(args)


if __name__ == "__main__":
    main()