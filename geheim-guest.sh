#!/usr/bin/env bash
set -euEo pipefail

function geheim-guest() {
    rp="$(realpath $0)"

    if [ $# -gt 1 ]
    then
        echo "Usage: $(basename $rp) [ip]"
        exit 1
    fi

    if [ $# -ne 1 ]
    then
        ip=$(curl -sS ipinfo.io/json | jq -r .ip)
    else
        ip=$1
    fi

    root_dir=$(dirname $rp)
    pushd "${root_dir}/terraform/ephemeral/guest"

    if ! [ -d .terraform/ ]
    then
        make
    fi

    terraform apply -auto-approve -var "guest_ip=${ip}"
    popd

    read -p "Press enter to continue. "

    pushd "${root_dir}/terraform/ephemeral/guest"
    terraform destroy -auto-approve -var "guest_ip=${ip}"
}

geheim-guest $@
