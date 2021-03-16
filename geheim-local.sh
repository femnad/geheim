#!/usr/bin/env bash
set -euEo pipefail

function geheim_local() {
    root_dir=$(dirname $(realpath $0))
    pushd "${root_dir}/playbooks"
    ansible-playbook local-sync.yml
    popd
}

geheim_local $@
