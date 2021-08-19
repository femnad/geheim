#!/usr/bin/env bash
set -euEo pipefail

function geheim_local() {
    if ! ssh-add -l > /dev/null 2>&1
    then
        ssh-add $HOME/.ssh/$(hostname -s)
    fi

    root_dir=$(dirname $(realpath $0))

    pushd "${root_dir}/playbooks"
    ansible-playbook local-sync.yml
    popd
}

geheim_local $@
