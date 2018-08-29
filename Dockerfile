FROM halplatform/hal-build-environments:terraform0.11
MAINTAINER Steve Kluck "stevekluck@quickenloans.com"

# This container includes:
# - Terraform 0.11.x
# - Terragrunt 0.14.x
# - Terragrunt 0.16.x
# - AWS CLI 1.14

# Download extra versions of terraform

RUN export TERRAFORM_VERSION="0.10.8" && \
    export TERRAFORM_BIN="/usr/bin/terraform-${TERRAFORM_VERSION}" && \
    curl -sSL -o "terraform.zip" "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" && \
    unzip "terraform.zip" && rm "terraform.zip" && mv "terraform" "${TERRAFORM_BIN}" && \
    chmod +x "${TERRAFORM_BIN}"

RUN export TERRAFORM_VERSION="0.11.8" && \
    export TERRAFORM_BIN="/usr/bin/terraform-${TERRAFORM_VERSION}" && \
    curl -sSL -o "terraform.zip" "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" && \
    unzip "terraform.zip" && rm "terraform.zip" && mv "terraform" "${TERRAFORM_BIN}" && \
    chmod +x "${TERRAFORM_BIN}"

# Download extra versions of terragrunt

RUN export TERRAGRUNT_VERSION="0.14.11" && \
    export TERRAGRUNT_BIN="/usr/bin/terragrunt-${TERRAGRUNT_VERSION}" && \
    curl -sSL -o "${TERRAGRUNT_BIN}" "https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_amd64" && \
    chmod +x "${TERRAGRUNT_BIN}"

RUN export TERRAGRUNT_VERSION="0.15.3" && \
    export TERRAGRUNT_BIN="/usr/bin/terragrunt-${TERRAGRUNT_VERSION}" && \
    curl -sSL -o "${TERRAGRUNT_BIN}" "https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_amd64" && \
    chmod +x "${TERRAGRUNT_BIN}"

RUN export TERRAGRUNT_VERSION="0.16.7" && \
    export TERRAGRUNT_BIN="/usr/bin/terragrunt-${TERRAGRUNT_VERSION}" && \
    curl -sSL -o "${TERRAGRUNT_BIN}" "https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_amd64" && \
    chmod +x "${TERRAGRUNT_BIN}"

# Scripts

COPY scripts /scripts
COPY support /terragrunt-support

RUN ln -s "/scripts/use-terraform.sh"         "/bin/use-terraform"      && \
    ln -s "/scripts/download-terraform.sh"    "/bin/download-terraform" && \
                                                                           \
    ln -s "/scripts/v2/terragrunt-plan.sh"    "/bin/plan-terraform-v2"  && \
    ln -s "/scripts/v2/terragrunt-apply.sh"   "/bin/apply-terraform-v2" && \
                                                                           \
    ln -s "/scripts/v2/terragrunt-plan.sh"    "/bin/plan-terraform"     && \
    ln -s "/scripts/v2/terragrunt-apply.sh"   "/bin/apply-terraform"
