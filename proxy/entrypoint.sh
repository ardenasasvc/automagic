#!/bin/sh
set -e

tailscaled --tun=userspace-networking --state=/tmp/tailscale-state &

tailscale up --authkey="${TS_AUTHKEY}" --hostname=ansible-runner

if [ "${DRY_RUN:-true}" = "false" ]; then
    exec ansible-playbook -i inventory.ini site.yml "$@"
else
    exec ansible-playbook -i inventory.ini site.yml "$@" --check
fi
