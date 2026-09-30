#!/bin/bash
## usage:   ./login.sh [router] [command...]
## purpose: ssh into a lab router using this root's terraform outputs
##          router defaults to the first one; a command runs non-interactively
set -euo pipefail
cd "$(dirname "$0")"

OUTPUTS=$(terraform output -json routers)
ROUTER_NAME="${1:-$(echo "${OUTPUTS}" | jq -r 'keys | first // empty')}"
[[ $# -gt 0 ]] && shift
[[ -n "${ROUTER_NAME}" ]] || { echo "[ LOGIN ] ERROR: no routers in terraform outputs" >&2; exit 1; }

ROUTER=$(echo "${OUTPUTS}" | jq -c --arg r "${ROUTER_NAME}" '.[$r] // empty')
[[ -n "${ROUTER}" ]] || {
	echo "[ LOGIN ] ERROR: unknown router [ ${ROUTER_NAME} ] - one of: $(echo "${OUTPUTS}" | jq -r 'keys | join(" ")')" >&2
	exit 1
}
ADDRESS=$(echo "${ROUTER}" | jq -r '.address')
SSH_USER=$(echo "${ROUTER}" | jq -r '.ssh_user')
SSH_KEY=$(echo "${ROUTER}" | jq -r '.ssh_private_key_file')

echo "[ ${ROUTER_NAME} ${SSH_USER}@${ADDRESS} ]" >&2
exec ssh -i "${SSH_KEY}" \
	-o IdentitiesOnly=yes \
	-o StrictHostKeyChecking=no \
	-o UserKnownHostsFile=/dev/null \
	-o LogLevel=ERROR \
	"${SSH_USER}@${ADDRESS}" "$@"
