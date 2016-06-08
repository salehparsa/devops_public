#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : devops_provision_os.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
## --
## Created : <2016-04-20>
## Updated: Time-stamp: <2016-06-08 13:37:55>
##-------------------------------------------------------------------
################################################################
# How To Use
#        export git_update_url="https://raw.githubusercontent.com/TEST/test/master/git_update.sh"
#        export ssh_email="auto.devops@test.com"
#
#        export ssh_public_key="AAAAB3NzaC1yc2EAAAADAQABAAABAQClL5PmH01x8eRPQ7FsodNT172ZIXiE2CT3RhBZpPpMFCdUyFTGBRfgbX/UE86MfycPHkzNnKemFNJOqFVdzK7eTIayxX9FYPOk+ONi2sbKkwAE4No+R0d4/ehoVzflbYXRWyxLqDKkqbJPDxY39xS2V7h4bSQWwrMyeYoGBn82AW5vSoonQMIrxe+bm6zWWtL6SzsYM/KNM1T+2pfU7Rq/YQPs2tf07rauyeT3bylhUf/CUqVPt2Xpf4qgmpGqp9Hyoy7FIfBHmCgXLRpia2KhpYr0j08s8cxBx1PEJiQ6EaWO2WlzyJIqgU2t9piDHEIUd6yCPmpshLtlOvno6KN5"
#
#        export ssh_config_content="Host github.com
#          StrictHostKeyChecking no
#          User git
#          HostName github.com
#          IdentityFile /root/.ssh/git_id_rsa"
#
#        export git_deploy_key="-----BEGIN RSA PRIVATE KEY-----
#        MIIJKgIBAAKCAgEAq6Jv5VPd82Lu2WE3R4/lNeA5Txckf3FE3aKRVBhRWy1ds1V9
#        ... ...
#        GnR17IjnTN5QS4/i6WhUuCU7F4OnIwjQETRCQtDJVU+VT5CKiIsUR7/VeaBruCFB
#        ZEtPc5dStJrtTrWRf1BOMlY/by7vaXII1Bkd+jSpLNqzfOpJdNWCaK+08bSOkA==
#        -----END RSA PRIVATE KEY-----"
#
#        bash ./enable_chef_depoyment.sh
################################################################
function log() {
    local msg=$*
    date_timestamp=$(date +['%Y-%m-%d %H:%M:%S'])
    echo -ne "$date_timestamp $msg\n"

    if [ -n "$LOG_FILE" ]; then
        echo -ne "$date_timestamp $msg\n" >> "$LOG_FILE"
    fi
}

################################################################
function enable_chef_deployment() {
    mkdir -p /root/.ssh/
    log "enable chef deployment"
    install_packages "wget" "wget"
    install_packages "curl" "curl"
    install_packages "git" "git"
    download_facility "$git_update_url" "/root/git_update.sh"

    if [ -n "$git_deploy_key" ]; then
        inject_git_deploy_key "/root/.ssh/git_id_rsa" "$git_deploy_key"
    fi

    if [ -n "$ssh_config_content" ]; then
        git_ssh_config "/root/.ssh/config" "$ssh_config_content"
    fi

    if [ -n "$ssh_public_key" ]; then
        inject_ssh_authorized_keys "$ssh_email" "$ssh_public_key"
    fi
    install_chef "$chef_version"
}

function install_chef() {
    local chef_version=${1?}
    if ! which chef-client 1>/dev/null 2>&1; then
        (echo "version=$chef_version"; curl -L https://www.opscode.com/chef/install.sh) |  bash
    fi
}

function install_packages() {
    local package=${1?}
    local binary_name=${2?}
    if ! which "$binary_name" 1>/dev/null 2>&1; then
        apt-get install -y "$package"
    fi
}

function download_facility() {
    local url=${1?}
    local dst_file=${2:?}
    if [ ! -f "$dst_file" ]; then
        command="wget -O $dst_file $url"
        log "$command"
        eval "$command"
        chmod 755 "$dst_file"
    fi
}

function inject_git_deploy_key() {
    local ssh_key=${1?}
    shift
    local ssh_key_content=$*

    log "inject git deploy key to $ssh_key"
    cat > "$ssh_key" <<EOF
$ssh_key_content
EOF
    chmod 400 "$ssh_key"
}

function git_ssh_config() {
    local ssh_config_file=${1?}
    shift
    local ssh_config_content="$*"

    log "configure $ssh_config_file"
    cat > "$ssh_config_file" <<EOF
$ssh_config_content
EOF
}

function inject_ssh_authorized_keys() {
    local ssh_email=${1?}
    local ssh_public_key=${2?}

    local ssh_authorized_key_file="/root/.ssh/authorized_keys"

    log "inject ssh authorized keys to $ssh_authorized_key_file"
    if ! grep "$ssh_email" $ssh_authorized_key_file 1>/dev/null 2>&1; then
        echo "$ssh_public_key" >> $ssh_authorized_key_file
    fi
}
####################################
export chef_version="12.4.1"
if [ -z "$git_update_url" ]; then
   export git_update_url="https://raw.githubusercontent.com/TOTVS/mdmpublic/master/git_update.sh"
fi

if [ -z "$ssh_email" ]; then
    export ssh_email="auto.devops@totvs.com"
fi

if [ -z "$ssh_config_content" ]; then
    export ssh_config_content="Host github.com
  StrictHostKeyChecking no
  User git
  HostName github.com
  IdentityFile /root/.ssh/git_id_rsa"
fi

ssh_public_key_file="/root/ssh_id_rsa.pub"
git_deploy_key_file="/root/git_deploy_key"

if [ -z "$ssh_public_key" ] && [ -f "$ssh_public_key_file" ]; then
    export ssh_public_key
    ssh_public_key=$(cat "$ssh_public_key_file")
fi

if [ -z "$git_deploy_key" ] && [ -f "$git_deploy_key_file" ]; then
    export git_deploy_key
    git_deploy_key=$(cat "$git_deploy_key_file")
fi

enable_chef_deployment
echo "Action Done"
## File : devops_provision_os.sh ends