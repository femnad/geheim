#!/usr/bin/env bash
set -euEo pipefail

function ansible_playbook() {
    export ANSIBLE_CONFIG="${HOME}/.config/ansible/ansible.cfg"
    ansible-playbook $@
}

function local_sync() {
    rp="$(realpath $0)"
    root_dir=$(dirname $rp)

    pushd "${root_dir}/playbooks"
    ansible_playbook local-sync.yml
    popd
}

function geheim_guest() {
    rp="$(realpath $0)"

    if [ $# -gt 1 ]
    then
        echo "Usage: $(basename $rp) [ip]"
        exit 1
    fi

    wait_for_sync=false

    if [ $# -ne 1 ]
    then
        ip=$(curl -sS ipinfo.io/json | jq -r .ip)
    else
        wait_for_sync=true
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

    if ! [ "$wait_for_sync" = true ]
    then
        local_sync
    else
        read -p "Press enter to continue. "
    fi

    pushd "${root_dir}/terraform/ephemeral/guest"
    terraform destroy -auto-approve -var "guest_ip=${ip}"
}

function geheim_local() {
    if ! ssh-add -l > /dev/null 2>&1
    then
        ssh-add $HOME/.ssh/$(hostname -s)
    fi

    root_dir=$(dirname $(realpath $0))

    local_sync
}

function geheim_wait() {
    export GEHEIM_WAIT=true

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

    current_ssid=$(nmcli --terse -f SSID,ACTIVE device wifi | grep -E ':yes$' | awk -F ':' '{print $1}')
    managed_ssid=$(pass meta/managed-connection/ssid)
    managed_connection=false

    if [ "$managed_ssid" = "$current_ssid" ]
    then
        managed_connection=true
    fi

    terraform apply -auto-approve -var "managed_connection=$managed_connection"
    popd

    pushd "${root_dir}/playbooks"
    ansible_playbook enable-password-sync.yml
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
        wait)
            shift
            geheim_wait $@
            ;;
        *)
            echo "Unrecognized subcommand ${subcommand}"
            exit 1
            ;;
    esac
}

main $@
