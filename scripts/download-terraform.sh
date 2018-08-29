#! /usr/bin/env bash

set -eo pipefail

# 31 = red      32 = green         33 = yellow
function clrd() {
    echo -e "\033[${3:-0};$2m$1\033[0m"
}

function clrn() {
    echo -n -e "\033[${3:-0};$2m$1\033[0m"
}

function usage_instructions {
    if [ "$1" == "" ] ; then
        return
    fi

    clrd "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓" 33
    clrd "┃  INSTRUCTIONS                                                            ┃" 33
    clrd "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛" 33
    echo
    echo "Parameters:"
    echo
    clrn "  " 32 ; clrn "--terraform  " 36 ; clrd ": Desired version of Terraform" 32
    echo "                 Leave empty or do not pass to skip download."
    echo
    clrn "  " 32 ; clrn "--terragrunt " 36 ; clrd ": Desired version of Terragrunt" 32
    echo "                 Leave empty or do not pass to skip download."
    echo
    clrn "  " 32 ; clrn "--bin-dir    " 36 ; clrd ": Where to download binaries to" 32
    echo "                 Default: /usr/bin"
    echo

    exit 0
}

function get_terraform {
    clrd "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓" 33
    clrd "┃  DOWNLOADING TERRAFORM                                                   ┃" 33
    clrd "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛" 33

    local readonly desired_version="$1"
    local readonly bin_dir="$2"
    local readonly tf_binary_file="${bin_dir}/terraform-${desired_version}"
    local readonly download_url="https://releases.hashicorp.com/terraform/${desired_version}/terraform_${desired_version}_linux_amd64.zip"

    echo
    if [ -z "$desired_version" ] ; then
        echo "No version of terraform set. Skipping download..."
        return
    fi

    echo "Downloading version \"${desired_version}\" from \"${download_url}\""
    echo

    curl -sSL -o "terraform.zip" \
        "${download_url}"

    unzip "terraform.zip" &&
        rm "terraform.zip" &&
        mv "terraform" "${tf_binary_file}"

    chmod +x "${tf_binary_file}"

    echo "Terraform downloaded to \"${tf_binary_file}\""
}

function get_terragrunt {
    clrd "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓" 33
    clrd "┃  DOWNLOADING TERRAGRUNT                                                  ┃" 33
    clrd "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛" 33

    local readonly desired_version="$1"
    local readonly bin_dir="$2"
    local readonly tf_binary_file="${bin_dir}/terragrunt-${desired_version}"
    local download_url="https://github.com/gruntwork-io/terragrunt/releases/download/v${desired_version}/terragrunt_linux_amd64"

    echo
    if [ -z "$desired_version" ] ; then
        echo "No version of terragrunt set. Skipping download..."
        return
    fi


    echo "Downloading version \"${desired_version}\" from \"${download_url}\""
    echo

    curl -sSL -o "${tf_binary_file}" \
        "${download_url}"

    chmod +x "${tf_binary_file}"

    echo "Terragrunt downloaded to \"${tf_binary_file}\""
}

function run_script {
    local terraform_desired=""
    local terragrunt_desired=""
    local bin_dir="/usr/bin"
    local show_help=""

    while [[ $# > 0 ]]; do
        local key="$1"

        case "$key" in
            --terraform)
                terraform_desired="$2" ; shift
                ;;
            --terragrunt)
                terragrunt_desired="$2" ; shift
                ;;
            --bin-dir)
                bin_dir="$2" ; shift
                ;;
            --help)
                show_help="1"
                ;;
            *)
                echo "ERROR: Unrecognized argument: $key"
                exit 1
                ;;
        esac

        shift
    done

    if [[ -z "${terraform_desired}" && -z "${terragrunt_desired}" ]] ; then
        show_help="1"
    fi

    usage_instructions "${show_help}"
    get_terraform      "$terraform_desired"  "${bin_dir}"
    get_terragrunt     "$terragrunt_desired" "${bin_dir}"
}

run_script "$@"
exit 0
