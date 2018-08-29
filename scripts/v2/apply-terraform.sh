#! /usr/bin/env bash

set -eo pipefail

# 31 = red      32 = green         33 = yellow
function clrd() {
    echo -e "\033[${3:-0};$2m$1\033[0m"
}

function show_installed_versions {
    clrd "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓" 33
    clrd "┃  TERRAFORM VERSION                                                       ┃" 33
    clrd "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛" 33

    terraform -v
    terragrunt -v

    echo ""
}

function validate_parameters {
    local readonly tf_account="$1"
    local readonly tf_region="$2"
    local readonly tf_environment="$3"
    local readonly tf_module="$4"

    clrd "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓" 33
    clrd "┃  VALIDATE PARAMETERS                                                     ┃" 33
    clrd "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛" 33

    if [ -z "${tf_account}" ] ; then
        clrd "AWS Account is required." 31
        echo "Set this using the \$AWS_ACCOUNT environment variable."
        exit 1
    fi

    if [ -z "${tf_region}" ] ; then
        clrd "AWS Region is required." 31
        echo "Set this using the \$AWS_DEFAULT_REGION environment variable."
        exit 1
    fi

    if [ -z "${tf_environment}" ] ; then
        clrd "Environment is required." 31
        echo "Set this using the --environment environment variable."
        exit 1
    fi

    if [ -z "${tf_module}" ] ; then
        clrd "Infrastructure module is required." 31
        echo "Set this using the --module flag."
        exit 1
    fi
}

function validate_project {
    local readonly module_dir="$1"

    clrd "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓" 33
    clrd "┃  VALIDATE INFRASTRUCTURE PROJECT                                         ┃" 33
    clrd "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛" 33

    if [ ! -d "${module_dir}" ] ; then
        clrd "No config directory found for \"${module_dir}\"" 31
        exit 1
    else
        echo "Terragrunt project found: ${module_dir}"
    fi

    if [ ! -f "${module_dir}/terraform.tfvars" ] ; then
        clrd "No terraform.tfvars found in \"${module_dir}\"" 31
        exit 1
    fi

    config_invalid=false
    grep -q \
        "terragrunt" \
        "${module_dir}/terraform.tfvars" \
        || config_invalid=true

    if [ "${config_invalid}" == true ] ; then
        clrd "Invalid terragrunt configuration found." 31
        clrd "Terragrunt must be configured in your terraform.tfvars" 31
        exit 1
    fi

    code_files=$(find ${module_dir} -name '*.terragrunt-cache*' -prune -o -name '*.tf' -print -quit)

    if [ -n "${code_files}" ] ; then
        clrd "Terragrunt directories must only contain configuration files (.tfvars)" 31
        echo "Move all terraform code (.tf) to a separate module directory or external repo."
        echo "See https://github.com/gruntwork-io/infrastructure-live-acme for example project structure."

        exit 1
    fi

    echo
}

function validate_terraform_templates {
    local readonly working_dir="$1"

    clrd "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓" 33
    clrd "┃  TERRAFORM VALIDATE                                                      ┃" 33
    clrd "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛" 33

    cd "${working_dir}"

    terragrunt validate \
        --terragrunt-non-interactive \
        2>&1
}

function run_terraform_command {
    local readonly working_dir="$1"
    local readonly command="$2"

    cd "${working_dir}"

    if [ "${command}" == "apply" ] ; then
        run_apply

    elif [ ! -z "${command}" ] ; then
        run_command ${command}
    else
        # default to apply
        run_apply
    fi
}

function run_command {
    clrd "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓" 33
    clrd "┃  TERRAFORM COMMAND                                                       ┃" 33
    clrd "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛" 33
    echo "Running: terragrunt ${@}"

    terragrunt \
        $@ \
        --terragrunt-non-interactive \
        2>&1
}

function run_apply {
    clrd "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓" 33
    clrd "┃  TERRAFORM APPLY                                                         ┃" 33
    clrd "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛" 33

    if [ ! -f "$(pwd)/terraform.tfplan" ] ; then
        clrd "No terraform plan file found. Expected: \"terraform.tfplan\"" 31
        exit 1
    fi

    terragrunt apply \
        --terragrunt-non-interactive \
        -auto-approve \
        "$(pwd)/terraform.tfplan" \
        2>&1
}

function run_script {
    local readonly build_param_prefix="HAL_METADATA_"
    local readonly module_var="${build_param_prefix}MODULE"
    local readonly custom_var="${build_param_prefix}DEPLOY_COMMAND"
    local readonly custom_region_var="${build_param_prefix}REGION"

    local state_path
    local deployment_configuration

    local account
    local region
    local environment
    local module

    local working_dir
    local custom_command

    state_path="${HAL_METADATAPATH:=/terraform-state}"
    deployment_configuration="${HAL_CONTEXT}"

    account="${AWS_ACCOUNT}"
    region="${AWS_DEFAULT_REGION}"
    environment="${HAL_ENVIRONMENT%"-aws"}"
    module="${!module_var}"

    if [ -n "${AWS_ACCOUNT_PREFIX}" ] ; then
        account="${AWS_ACCOUNT_PREFIX}${account}"
    fi
    if [ -n "${ENVIRONMENT_PREFIX}" ] ; then
        environment="${ENVIRONMENT_PREFIX}${environment}"
    fi

    # Allow customization of the terraform command to run
    local custom_command=""
    if [ ! -z "${!custom_var}" ] ; then
        custom_command="${!custom_var}"
    fi

    # Allow customizations through cli parameters
    while [[ $# > 0 ]]; do
        local key="$1"

        case "$key" in
            --account)
                account="$2" ; shift
                ;;
            --region)
                region="$2" ; shift
                ;;
            --environment)
                environment="$2" ; shift
                ;;
            --module)
                module="$2" ; shift
                ;;
            *)
                echo "ERROR: Unrecognized argument: $key"
                exit 1
                ;;
        esac

        shift
    done

    # Require deployments to set module name in context
    if [ "${module}" != "${deployment_configuration}" ] ; then
        clrd "You must create a deployment target for each IAC module (specify module name in \$HAL_CONTEXT)" 31
        exit 1
    fi

    # Change region if set in build parameters
    if [ -n "${!custom_region_var}" ] ; then
        export AWS_DEFAULT_REGION="${!custom_region_var}"
        region="${!custom_region_var}"
        if [ -f "${BASH_ENV}" ] ; then
            echo 'export AWS_DEFAULT_REGION="'${!custom_region_var}'"' >> $BASH_ENV
        fi
    fi

    working_dir="$(pwd)/${account}/${region}/${environment}/${module}"

    export TF_STATE_PREFIX="${state_path}/${environment}.${module}."

    use-terraform --terragrunt "0.16.7"
    show_installed_versions

    validate_parameters          "${account}" "${region}" "${environment}" "${module}"
    (validate_project             "${working_dir}")
    validate_terraform_templates "${working_dir}"

    run_terraform_command        "${working_dir}" "${custom_command}"
}

run_script "$@"
exit 0
