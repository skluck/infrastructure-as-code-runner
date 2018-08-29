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
    if [ "$1" == "1" ] ; then
        return
    fi

    clrd "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓" 33
    clrd "┃  INSTRUCTIONS               \"--no-instructions\" to suppress this message ┃" 33
    clrd "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛" 33
    echo "Terragrunt is a thin wrapper for Terraform that provides extra tools for keeping your Terraform"
    echo "configurations DRY, working with multiple Terraform modules, and managing remote state."
    echo
    echo "Each terragrunt module you execute should have a hierarchy that follows this specification:"
    echo
    clrn "- ./" ; clrn "\$account_number" 36 ;
       clrn "/" ; clrn "\$region_name" 36 ;
       clrn "/" ; clrn "\$environment_name" 36 ;
       clrn "/" ; clrd "\$module_name" 36

    echo
    echo "Parameters:"
    echo
    clrn "- " 32 ; clrn "\$account_number   " 36 ; clrd ": AWS account" 32
    clrd "                      Set with \$AWS_ACCOUNT or --account \"\$account_number\"" 32
    clrd
    clrn "- " 32 ; clrn "\$region_name      " 36 ; clrd ": AWS region name or \"_global\" for region-less services (such as IAM or Route53)" 32
    clrd "                      Set with \$AWS_DEFAULT_REGION or --region \"\$region_name\"" 32
    echo
    clrn "- " 32 ; clrn "\$environment_name " 36 ; clrd ": dev, test, beta, prod, etc (Do not use \"-aws\" suffix)" 32
    clrd "                      Set this using the --environment environment variable" 32
    echo
    clrn "- " 32 ; clrn "\$module_name      " 36 ; clrd ": The name of the infrastructure module to run" 32
    clrd "                      Set this using the --module flag" 32
    echo
    echo "Other options:"
    echo "- Prefix a value to \"\$account_number\" with \$AWS_ACCOUNT_PREFIX"
    echo "- Prefix a value to \"\$environment_name\" with \$ENVIRONMENT_PREFIX"
    echo
    echo "Destroying infrastructure:"
    echo "- Set \$HAL_METADATA_DESTROY to any non-empty value such as \"1\" (\"destroy\" build parameter)"
    echo "  This will trigger a terragrunt destroy."
    echo
    echo "Running commands other than plan|apply|destroy:"
    echo "- Run a custom terragrunt command by setting \$HAL_METADATA_CUSTOM_COMMAND (\"custom_command\" build parameter)"
    echo "- To run a custom command during deploy, set \$HAL_METADATA_DEPLOY_COMMAND (\"deploy_command\" push parameter)"
    echo
    echo "------------------------------------------------------------------------------------------------------------------------"
    echo
    echo "For multi-module projects \$HAL_METADATA_MODULE is always required and should not be hardcoded."
    echo
    echo "Examples of projects with this infrastructure layout:"
    echo -n "- " ; clrd "https://github.com/gruntwork-io/infrastructure-live-acme" 32
    echo
}

function show_installed_versions {
    clrd "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓" 33
    clrd "┃  TERRAFORM VERSION                                                       ┃" 33
    clrd "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛" 33

    terraform -v
    terragrunt -v

    echo
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
        echo "Set this using the \$HAL_ENVIRONMENT environment variable."
        exit 1
    fi

    if [ -z "${tf_module}" ] ; then
        clrd "Infrastructure module is required." 31
        echo "Set this using the \$HAL_METADATA_MODULE environment variable (Build parameters)."
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
        "terragrunt_source" \
        "${module_dir}/terraform.tfvars" \
        || config_invalid=true

    if [ "${config_invalid}" == true ] ; then
        clrd "Invalid terragrunt configuration found." 31
        clrd "\"terragrunt_source\" must be configured in your terraform.tfvars" 31
        echo
        echo "Please see instructions here on how to structure IAC projects:"
        echo "https://hal9000/help/application-setup#iac-terraform"
        exit 1
    fi

    code_files=$(find ${module_dir} -name '*.terragrunt-cache*' -prune -o -name '*.tf' -print -quit)

    if [ -n "${code_files}" ] ; then
        clrd "Terragrunt directories must only contain configuration files (.tfvars)" 31
        echo
        echo "Move all terraform code (.tf) to a separate module directory or external repo."
        echo "See https://git.rockfin.com/gruntwork/infrastructure-live-acme for example project structure."

        exit 1
    fi

    echo
}

function prepare_project {
    local readonly module_dir="$1"
    local readonly account_dir="$2"
    local readonly source_backend_file="$3"
    local readonly source_base_tfvars_file="$4"
    local readonly source_module_tfvars_file="$5"

    clrd "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓" 33
    clrd "┃  PREPARE INFRASTRUCTURE PROJECT                                          ┃" 33
    clrd "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛" 33


    # Set default backend.tf (so modules dont need to hardcode a backend)
    echo
    echo ">> Configuring Backend"

    if [ ! -f "${account_dir}/backend.tf" ] ; then
        echo "No backend.tf found in \"${account_dir}\""

    else
        echo "\"backend.tf\" found in account directory. Removing..."
        rm "${account_dir}/backend.tf"
    fi

    echo "Setting backend to \"local\""
    cp "${source_backend_file}" "${account_dir}/backend.tf"

    # Set base terraform.tfvars (Which auto-copies backend and loads nested tfvars)
    echo
    echo ">> Configuring base terragrunt configuration"

    if [ ! -f "${account_dir}/terraform.tfvars" ] ; then
        echo "No base terraform.tfvars found in \"${account_dir}\""
    else
        echo "Base \"terraform.tfvars\" found in account directory. Removing..."
        rm "${account_dir}/terraform.tfvars"
    fi

    echo "Setting base \"terraform.tfvars\""
    cp "${source_base_tfvars_file}" "${account_dir}/terraform.tfvars"

    # Set module terraform.tfvars
    echo
    echo ">> Configuring module terragrunt configuration"

    local terragrunt_source
    terragrunt_source=$(cat ${module_dir}/terraform.tfvars | grep "terragrunt_source" | rev | cut -d'"' -f2 | rev)

    if [ -z "${terragrunt_source}" ] ; then
        clrd "Terragrunt source not found." 31
        clrd "\"terragrunt_source\" must be configured in your terraform.tfvars" 31
        echo
        echo "Example:"
        echo "terragrunt_source = \"git::https://git.rockfin.com/terraform/aws-vpc-tf.git?ref=1.0.2\""
        exit 1
    fi

    echo "Setting module \"terraform.tfvars\""

    # Set the true module source into the terragrunt config and append it to the
    # project's standard terraform tfvars
    cp "${source_module_tfvars_file}" "${module_dir}/module.terraform.tfvars.initial"
    sed "s+__module_path_or_url__+${terragrunt_source}+" "${module_dir}/module.terraform.tfvars.initial" \
        > "${module_dir}/module.terraform.tfvars" && \
        rm "${module_dir}/module.terraform.tfvars.initial"

    # We have 2 separate config files instead of concatting them together because terragrunt
    # messes up terraform escaping in config.
    mv "${module_dir}/terraform.tfvars"        "${module_dir}/config.auto.tfvars"
    mv "${module_dir}/module.terraform.tfvars" "${module_dir}/terraform.tfvars"
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

    if [ "${command}" == "destroy" ] ; then
        run_destroy_plan

    elif [ "${command}" == "plan" ] ; then
        run_plan

    elif [ ! -z "${command}" ] ; then
        run_command ${command}
    else
        # default to plan
        run_plan
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

function run_plan {
    clrd "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓" 33
    clrd "┃  TERRAFORM PLAN                                                          ┃" 33
    clrd "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛" 33

    terragrunt plan \
        --terragrunt-non-interactive \
        -out="$(pwd)/terraform.tfplan" \
        2>&1
}

function run_destroy_plan {
    clrd "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓" 31
    clrd "┃                                                                                                         ┃" 31
    clrd "┃    ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓   ┃" 31
    clrd "┃    ┃                                                                                                ┃   ┃" 31
    clrd "┃    ┃  TERRAFORM DESTROY                                                                             ┃   ┃" 31
    clrd "┃    ┃                                                                                                ┃   ┃" 31
    clrd "┃    ┃  OMG! YOU'RE DESTROYING INFRASTRUCTURE!                                                        ┃   ┃" 31
    clrd "┃    ┃                                                                                                ┃   ┃" 31
    clrd "┃    ┃  BE CAREFUL!!!!!                                                                               ┃   ┃" 31
    clrd "┃    ┃                                                                                                ┃   ┃" 31
    clrd "┃    ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛   ┃" 31
    clrd "┃                                                                                                         ┃" 31
    clrd "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛" 31

    terragrunt plan \
        -destroy \
        --terragrunt-non-interactive \
        -out="$(pwd)/terraform.tfplan" \
        2>&1
}

function run_script {
    local readonly build_param_prefix="HAL_METADATA_"
    local readonly module_var="${build_param_prefix}MODULE"
    local readonly destroy_var="${build_param_prefix}DESTROY"
    local readonly custom_var="${build_param_prefix}CUSTOM_COMMAND"
    local readonly custom_region_var="${build_param_prefix}REGION"

    local readonly backend_file="/terragrunt-support/backend.tf"
    local readonly base_file="/terragrunt-support/base.terraform.tfvars"
    local readonly module_file="/terragrunt-support/module.terraform.tfvars"

    local state_path

    local account
    local region
    local environment
    local module

    local account_dir
    local working_dir
    local custom_command
    local skip_usage

    state_path="${HAL_METADATAPATH:=/terraform-state}"

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
    custom_command=""
    if [ ! -z "${!destroy_var}" ] ; then
        custom_command="destroy"

    elif [ ! -z "${!custom_var}" ] ; then
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
            --no-instructions)
                skip_usage="1"
                ;;
            *)
                echo "ERROR: Unrecognized argument: $key"
                exit 1
                ;;
        esac

        shift
    done

    # Change region if set in build parameters
    if [ -n "${!custom_region_var}" ] ; then
        export AWS_DEFAULT_REGION="${!custom_region_var}"
        region="${!custom_region_var}"
        if [ -f "${BASH_ENV}" ] ; then
            echo 'export AWS_DEFAULT_REGION="'${!custom_region_var}'"' >> $BASH_ENV
        fi
    fi

    account_dir="$(pwd)/${account}"
    working_dir="$(pwd)/${account}/${region}/${environment}/${module}"

    export TF_STATE_PREFIX="${state_path}/${environment}.${module}."

    use-terraform --terragrunt "0.16.7"
    usage_instructions "${skip_usage}"
    show_installed_versions

    validate_parameters          "${account}"     "${region}" "${environment}" "${module}"
    (validate_project            "${working_dir}")
    prepare_project              "${working_dir}" "${account_dir}" "${backend_file}" "${base_file}" "${module_file}"
    validate_terraform_templates "${working_dir}"

    run_terraform_command        "${working_dir}" "${custom_command}"

    # Remove the custom backend.tf from the module dir if it exists.
    if [ -f "${working_dir}/backend.tf" ] ; then
        rm "${working_dir}/backend.tf"
    fi
}

run_script "$@"
exit 0
