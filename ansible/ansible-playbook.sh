#!/bin/bash
#
# $ ./ansible-playbook.sh -i [local or production] fswiki-playbook.yml
SCRIPT_DIR=$(dirname "$0")
# https://gist.github.com/berkayunal/ccb1c3511f02d41b7654de17bced30b7
set -o nounset -o pipefail -o errexit

# Load all variables from .env and export them all for Ansible to read
set -o allexport
if [ -e "${SCRIPT_DIR}/.env" ]; then
  source "${SCRIPT_DIR}/.env"
fi
set +o allexport

# Get dependencies (-f option force ansible to update role)
ansible-galaxy collection install -r requirements.yml

# Run Ansible
ansible-playbook "$@"
