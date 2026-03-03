# automagic

Infrastructure-as-code repo managing Tailscale network ACLs, an Nginx reverse proxy, and Proxmox VE provisioning via Ansible.

## Architecture

Three independent subsystems:

- **`network/`** — Tailscale ACL policy (`policy.hujson`), synced to the tailnet. HuJSON format (JSON with comments and trailing commas).
- **`proxy/`** — Ansible playbook that connects to the proxy host over Tailscale to configure Nginx + Certbot.
- **`pve/`** — Ansible playbook that configures the Proxmox host (`pve`) via its HTTP API. Uses `connection: local` with Tailscale for hostname resolution. Manages the `automata@pve` user, ACLs, and API tokens using `community.proxmox` collection modules and `uri` calls.

## Setup

Secrets live in vault-encrypted files (`pve/ansible/group_vars/all/vault.yml`). The vault password lives in `vault-pass` (gitignored) and is picked up automatically via `ansible.cfg`. Hosts (`proxy`, `pve`) are resolved over Tailscale — your machine must be on the tailnet.

```sh
# install collections
ansible-galaxy collection install -r proxy/ansible/requirements.yml
ansible-galaxy collection install -r pve/ansible/requirements.yml
```

## Commands

### Proxy

```sh
# dry-run
ansible-playbook -i proxy/ansible/inventory.ini proxy/ansible/site.yml --check

# apply
ansible-playbook -i proxy/ansible/inventory.ini proxy/ansible/site.yml
```

### PVE

```sh
# dry-run
ansible-playbook -i pve/ansible/inventory.ini pve/ansible/site.yml --check

# apply
ansible-playbook -i pve/ansible/inventory.ini pve/ansible/site.yml

# update DNS records only
ansible-playbook -i pve/ansible/inventory.ini pve/ansible/site.yml --tags dns-records
```

### Container alternative

Both playbooks can also run inside containers that handle Tailscale connectivity automatically. Build context is the repo root; `vault-pass` must exist before building. Pass `TS_AUTHKEY` at runtime.

```sh
# proxy
podman build -t automagic-proxy -f proxy/Containerfile .
podman run --rm -e TS_AUTHKEY=... automagic-proxy              # dry-run
podman run --rm -e TS_AUTHKEY=... -e DRY_RUN=false automagic-proxy   # apply

# pve
podman build -t automagic-pve -f pve/Containerfile .
podman run --rm -e TS_AUTHKEY=... automagic-pve                # dry-run
podman run --rm -e TS_AUTHKEY=... -e DRY_RUN=false automagic-pve     # apply
```

## Key conventions

- **ACL policy** — `network/policy.hujson` is HuJSON. Keep comments explaining rules; preserve trailing commas.
- **Nginx configs** — Source files live in `proxy/nginx/`. Site configs go in `proxy/nginx/sites-available/`. The nginx Ansible role deploys these to the remote host.
- **Ansible roles** — `proxy/ansible/roles/{nginx,certbot}`. Roles reference source configs via relative paths (`{{ role_path }}/../../../nginx/`).
- **Inventory** — `proxy/ansible/inventory.ini` uses the Tailscale hostname `proxy` to reach the target host.
- **PVE playbook** — `pve/ansible/roles/pve_user`. Uses `connection: local` and talks to the Proxmox API over HTTPS. Auth is `PVEAPIToken` via vault-encrypted variables.

## Secrets

Never commit secrets in plain text. The `.gitignore` excludes `secrets/`, `*.env*`, and `vault-pass`. Secrets are stored in `pve/ansible/group_vars/all/vault.yml` (ansible-vault encrypted, safe to commit). The vault password lives in `vault-pass` and is referenced by `ansible.cfg` so no flags are needed at runtime.
