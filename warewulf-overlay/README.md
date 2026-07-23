# warewulf-overlay/ — compute-node files (NOT deployed by the 78 playbook)

The `78-deploy-ood-server.yaml` playbook runs on the **OOD login/web node** and
deploys ~99% of this repo (`etc/ood`, `var/www/ood`, `opt/ood`, `usr/local/bin`).
The files in this directory are the exception: they must live on the **compute
nodes** (where the OOD desktop/app jobs actually run), so they go into the
Warewulf compute-node overlay/image — not via the playbook.

## Files

| Overlay path | Purpose |
|---|---|
| `etc/sudoers.d/mkice` | Lets any user run `create-ice.sh` as root for their OWN uid (sets up `/run/user/$UID` + `/tmp/.ICE-unix` for VNC sessions). |
| `usr/local/bin/create-ice.sh` | The hardened script (validates uid, enforces caller-owns-uid via SUDO_UID). |

## Security (tightened 2026-07-23)

Previously `ALL ALL=(ALL) NOPASSWD: /usr/local/bin/create-ice.sh` — any user could
run it as any user, and the script did `rm -rf "/run/user/$1"` with no validation
(empty arg → `rm -rf /run/user/`; `../..` → traversal). Now:

- sudoers: `ALL ALL=(root) NOPASSWD: /usr/local/bin/create-ice.sh *` (root target only)
- script: rejects non-integer/zero uid; under sudo refuses any uid ≠ `SUDO_UID`

## Deploying to compute nodes

Copy this tree into the Warewulf overlay (e.g. on the WW server 172.26.92.10):

```bash
# on the WW server, into the compute-node overlay root
sudo cp -r warewulf-overlay/* /path/to/ww/overlay/root/
sudo chmod 0440 /path/to/ww/overlay/root/etc/sudoers.d/mkice
sudo chmod 0755 /path/to/ww/overlay/root/usr/local/bin/create-ice.sh
# rebuild the overlay / reimage nodes as needed
```

Validate before relying on it: `sudo -u someuser sudo -n /usr/local/bin/create-ice.sh $(id -u someuser)` should succeed; passing another uid should refuse.
