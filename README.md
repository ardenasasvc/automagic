# automagic

Infrastructure-as-code for a home lab. Manages Tailscale network ACLs, an Nginx reverse proxy, and Proxmox VE provisioning via Ansible playbooks.

## Structure

```
network/   Tailscale ACL policy (policy.hujson)
proxy/     Ansible playbook for Nginx + Certbot on the proxy host
pve/       Ansible playbook for Proxmox (VMs, LXC containers, DNS, Forgejo)
```

## Prerequisites

Hosts (`proxy`, `pve`) are resolved over Tailscale — your machine must be on the tailnet.

Secrets live in vault-encrypted files (`pve/ansible/group_vars/all/vault.yml`). The vault password lives in `vault-pass` (gitignored) and is picked up automatically via `ansible.cfg`.

```sh
# install collections
ansible-galaxy collection install -r proxy/ansible/requirements.yml
ansible-galaxy collection install -r pve/ansible/requirements.yml
```

## Proxy

```sh
# dry-run
ansible-playbook -i proxy/ansible/inventory.ini proxy/ansible/site.yml --check

# apply
ansible-playbook -i proxy/ansible/inventory.ini proxy/ansible/site.yml
```

## PVE

```sh
# dry-run
ansible-playbook -i pve/ansible/inventory.ini pve/ansible/site.yml --check

# apply
ansible-playbook -i pve/ansible/inventory.ini pve/ansible/site.yml

# update DNS records only
ansible-playbook -i pve/ansible/inventory.ini pve/ansible/site.yml --tags dns-records
```

## Container alternative

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
