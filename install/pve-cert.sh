#!/bin/bash
## generates a certificate with tailscale and tells proxmox to serve using it

NAME="$(tailscale status --json | jq '.Self.DNSName | .[:-1]' -r)"
tailscale cert "${NAME}"
pvenode cert set "${NAME}.crt" "${NAME}.key" --force --restart

## another option is to use tailscale serve
# 
# tailscale serve --bg https+insecure://localhost:8006