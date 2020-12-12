#!/usr/bin/env bash
set -euEo pipefail

function geheim() {
    root_dir=$(dirname $0)
    pushd "${root_dir}/terraform/ephemeral"
    terraform apply -auto-approve
    popd
    pushd "${root_dir}/playbooks"
    ansible-playbook enable-password-sync.yml
    popd
    pushd "${root_dir}/terraform/ephemeral"
    terraform destroy -auto-approve
}

geheim $@
