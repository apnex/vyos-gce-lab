#!/bin/bash
## usage:   ./login.sh [host] [command...]
## purpose: ssh into the NVA or a test VM using this root's terraform outputs;
##          test VMs have no external address and are reached through the NVA
##          host defaults to nva; a command runs non-interactively
set -euo pipefail
cd "$(dirname "$0")"

OUTPUTS=$(terraform output -json hosts)
HOST_NAME="${1:-nva}"
[[ $# -gt 0 ]] && shift

HOST=$(echo "${OUTPUTS}" | jq -c --arg h "${HOST_NAME}" '.[$h] // empty')
[[ -n "${HOST}" ]] || {
	echo "[ LOGIN ] ERROR: unknown host [ ${HOST_NAME} ] - one of: $(echo "${OUTPUTS}" | jq -r 'keys | join(" ")')" >&2
	exit 1
}
ADDRESS=$(echo "${HOST}" | jq -r '.address')
SSH_USER=$(echo "${HOST}" | jq -r '.ssh_user')
SSH_KEY=$(echo "${HOST}" | jq -r '.ssh_private_key_file')
SSH_OPTS=(-o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR)

if [[ $(echo "${HOST}" | jq -r '.jump') == "true" ]]; then
	NVA=$(echo "${OUTPUTS}" | jq -c '.nva')
	JUMP="$(echo "${NVA}" | jq -r '.ssh_user')@$(echo "${NVA}" | jq -r '.address')"
	JUMP_KEY=$(echo "${NVA}" | jq -r '.ssh_private_key_file')
	SSH_OPTS+=(-o "ProxyCommand=ssh -i ${JUMP_KEY} ${SSH_OPTS[*]} -W %h:%p ${JUMP}")
	echo "[ ${HOST_NAME} ${SSH_USER}@${ADDRESS} via ${JUMP} ]" >&2
else
	echo "[ ${HOST_NAME} ${SSH_USER}@${ADDRESS} ]" >&2
fi
exec ssh -i "${SSH_KEY}" "${SSH_OPTS[@]}" "${SSH_USER}@${ADDRESS}" "$@"
