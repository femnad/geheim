#!/usr/bin/env bash
set -euEo pipefail

function geheim() {
    pushd terraform/ephemeral
    terraform apply -auto-approve
    popd
    pushd playbooks
    ansible-playbook enable-password-sync.yml
    popd
    pushd terraform/ephemeral
    terraform destroy -auto-approve
}

geheim $@
