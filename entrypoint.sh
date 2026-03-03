#!/bin/sh
set -e

export ANSIBLE_VAULT_PASSWORD_FILE=/secrets/vault-pass

tailscaled --tun=userspace-networking --state=/tmp/tailscale-state &

tailscale up --authkey="${TS_AUTHKEY}" --hostname="${TS_HOSTNAME:-ansible-runner}"

if [ "${DRY_RUN:-true}" = "false" ]; then
    exec ansible-playbook -i inventory.ini site.yml "$@"
else
    exec ansible-playbook -i inventory.ini site.yml "$@" --check
fi
