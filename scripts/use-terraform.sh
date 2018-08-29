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
    echo "                 Leave empty or do not pass to skip switching to this version."
    echo
    clrn "  " 32 ; clrn "--terragrunt " 36 ; clrd ": Desired version of Terragrunt" 32
    echo "                 Leave empty or do not pass to skip switching to this version."
    echo
    clrn "  " 32 ; clrn "--bin-dir    " 36 ; clrd ": Where to look for version binaries" 32
    echo "                 Default: /usr/bin"
    echo

    exit 0
}

function get_current_version {
    local readonly name="$1"
    local version

    (
        is_installed=$(command -v "$name")
    )

    if [ $? -eq 1 ] ; then
        exit 0
    fi

    version=$(CHECKPOINT_DISABLE=1 $name -v | rev | cut -dv -f1 | rev)

    echo $version
}

function find_binary {
    local readonly name="$1"
    local installed

    installed=($(command -v "$name"))

    if [ $? -eq 1 ] ; then
        exit 0
    fi

    echo $installed
}

function use_terraform {
    clrd "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓" 33
    clrd "┃  UPDATING TERRAFORM                                                      ┃" 33
    clrd "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛" 33

    local readonly current_version="$1"
    local readonly desired_version="$2"
    local readonly bin_dir="$3"

    local tf_binary_file="${bin_dir}/terraform"
    local binary_file
    local old_binary_file

    echo "Current version: \"${current_version}\""
    echo

    if [ -z "$desired_version" ] ; then
        echo "No desired version of terraform set."
        return
    fi

    if [ "${current_version}" == "${desired_version}" ] ; then
        echo "Desired version matches currently installed version."
        return
    fi

    echo "Switching to \"${desired_version}\""

    binary_file=$(find_binary "terraform-${desired_version}")
    if [ ! -f "$binary_file" ] ; then
        echo "Desired version: \"${desired_version}\""
        echo
        echo "Desired version of terraform not found."
        exit 1
    fi

    old_binary_file=$(find_binary "terraform")
    if [ -f "$old_binary_file" ] ; then
        mv "$old_binary_file" "${old_binary_file}.old"
        tf_binary_file="${old_binary_file}"
    fi

    ln -s "${binary_file}" "${tf_binary_file}"
}

function use_terragrunt {
    clrd "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓" 33
    clrd "┃  UPDATING TERRAGRUNT                                                     ┃" 33
    clrd "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛" 33

    local readonly current_version="$1"
    local readonly desired_version="$2"
    local readonly bin_dir="$3"

    local tf_binary_file="${bin_dir}/terragrunt"
    local binary_file
    local old_binary_file

    echo "Current version: \"${current_version}\""
    echo

    if [ -z "$desired_version" ] ; then
        echo "No desired version of terragrunt set."
        return
    fi

    if [ "${current_version}" == "${desired_version}" ] ; then
        echo "Desired version matches currently installed version."
        return
    fi

    echo "Switching to \"${desired_version}\""

    binary_file=$(find_binary "terragrunt-${desired_version}")
    if [ ! -f "$binary_file" ] ; then
        echo "Desired version: \"${desired_version}\""
        echo
        echo "Desired version of terragrunt not found."
        exit 1
    fi

    old_binary_file=$(find_binary "terragrunt")
    if [ -f "$old_binary_file" ] ; then
        mv "$old_binary_file" "${old_binary_file}.old"
        tf_binary_file="${old_binary_file}"
    fi

    ln -s "${binary_file}" "${tf_binary_file}"
}

function run_script {
    local terraform_version
    local terragrunt_version

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

    terraform_version=$(get_current_version "terraform")
    terragrunt_version=$(get_current_version "terragrunt")

    use_terraform "${terraform_version}"   "${terraform_desired}"  "${bin_dir}"
    use_terragrunt "${terragrunt_version}" "${terragrunt_desired}" "${bin_dir}"
}

run_script $@
