# automagic

Infrastructure-as-code repo managing Tailscale network ACLs and an Nginx reverse proxy via Ansible.

## Architecture

Two independent subsystems:

- **`network/`** — Tailscale ACL policy (`policy.hujson`), synced to the tailnet. HuJSON format (JSON with comments and trailing commas).
- **`proxy/`** — Containerized Ansible that connects to the proxy host over Tailscale to configure Nginx + Certbot. The container runs `tailscaled` in userspace mode, authenticates with `TS_AUTHKEY`, then executes the playbook.

## Commands

Build the Ansible runner container:
```sh
podman build -t automagic-proxy proxy/
```

Run the playbook (dry-run by default via `--check` in entrypoint):
```sh
podman run --rm -e TS_AUTHKEY="<key>" automagic-proxy
```

Apply changes for real (disable dry-run):
```sh
podman run --rm -e TS_AUTHKEY="<key>" -e DRY_RUN=false automagic-proxy
```

Pass extra ansible-playbook flags after the image name:
```sh
podman run --rm -e TS_AUTHKEY="<key>" automagic-proxy --diff
```

Install Ansible Galaxy dependencies locally:
```sh
ansible-galaxy collection install -r proxy/ansible/requirements.yml
```

## Key conventions

- **ACL policy** — `network/policy.hujson` is HuJSON. Keep comments explaining rules; preserve trailing commas.
- **Nginx configs** — Source files live in `proxy/nginx/`. Site configs go in `proxy/nginx/sites-available/`. The nginx Ansible role deploys these to the remote host.
- **Ansible roles** — `proxy/ansible/roles/{nginx,certbot}`. Roles reference source configs via relative paths (`{{ role_path }}/../../../nginx/`).
- **Inventory** — `proxy/ansible/inventory.ini` uses the Tailscale hostname `proxy` to reach the target host.

## Secrets

Never commit secrets in plain text. The `.gitignore` excludes `secrets/`. Sensitive values (`TS_AUTHKEY`, API keys, domains/emails in role defaults) should come from environment variables, Ansible vault, or an external secret store.
