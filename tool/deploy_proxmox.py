"""Backward-compatible entrypoint for the Proxmox LXC deployment.

Equivalent to:
    python tool/deploy.py deploy --target lxc [--init-env]
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from deploy import main  # noqa: E402

forwarded = [arg for arg in sys.argv[1:] if arg.startswith("-")]
sys.argv = ["tool/deploy.py", "deploy", "--target", "lxc"] + forwarded
main()