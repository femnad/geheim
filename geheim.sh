#!/usr/bin/env bash
set -euEo pipefail

function geheim() {
    if ! ssh-add -l > /dev/null 2>&1
    then
        echo 'SSH agent has no identities'
        exit 1
    fi

    root_dir=$(dirname $(realpath $0))
    pushd "${root_dir}/terraform/ephemeral"

    if ! [ -d .terraform/ ]
    then
        make
    fi

    terraform apply -auto-approve
    popd

    pushd "${root_dir}/playbooks"
    ansible-playbook enable-password-sync.yml
    popd

    pushd "${root_dir}/terraform/ephemeral"
    terraform destroy -auto-approve
}

geheim $@
