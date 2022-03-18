#!/usr/bin/env bash
set -euEo pipefail

function geheim_guest() {
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

function geheim_no_wait() {
    export GEHEIM_NO_WAIT=true

    geheim
}

function geheim() {
    if ! ssh-add -l > /dev/null 2>&1
    then
        ssh-add $HOME/.ssh/$(hostname -s)
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

function main() {
    if [ $# -eq 0 ]
    then
        geheim
        return
    fi

    subcommand="$1"
    case $subcommand in
        local)
            shift
            geheim_local $@
            ;;
        guest)
            shift
            geheim_guest $@
            ;;
        nowait)
            shift
            geheim_no_wait $@
            ;;
        *)
            echo "Unrecognized subcommand ${subcommand}"
            exit 1
            ;;
    esac
}

main $@
