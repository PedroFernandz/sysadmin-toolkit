#!/bin/bash

# SSH user and domain suffix used to build the alias command, and the
# aliases file to edit; all overridable via environment variables.
ssh_user="${SSH_ALIAS_USER:-root}"
ssh_domain="${SSH_ALIAS_DOMAIN:-domain.i.want}"
bash_aliases_file="${BASH_ALIASES_FILE:-${HOME}/.bash_aliases}"

if [ ${#} -ne 1 ]; then
  echo "Usage: ${0} <alias_name>"
  exit 1
fi

alias_name="${1}"
host_name="${alias_name}"

alias_command="ssh ${ssh_user}@${alias_name}.${ssh_domain}"

# Check if the alias already exists in the bash aliases file
if grep -q "${alias_name}" "${bash_aliases_file}"; then
  echo "Alias '${alias_name}' already exists in ${bash_aliases_file}"
else
  echo "alias ${alias_name}='${alias_command}'" >> "${bash_aliases_file}"
  source "${bash_aliases_file}"
  echo "Alias '${alias_name}' added for host '${host_name}'"
fi
