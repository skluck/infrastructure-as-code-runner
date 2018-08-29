# Infrastructure as Code - Runner

A docker environment and set of scripts that make running terraform safe and consistent.

## Summary

The purpose of these scripts is to add the safety and consistency of [Terragrunt](https://github.com/gruntwork-io/terragrunt)
when *running* infrastructure changes without requiring modules to change their configuration or developers to be aware of
specific configuration requirements of Terragrunt (or at least to minimize it).

As you add more instructure as code, modules should be separated to make execution safe and reliable. Terragrunt and this
repository provide a way to organize infrastructure as code projects in a scalable manner.

Please review **Terragrunt** and get familiar before jumping in. The gist of it is that projects should be organized in layers
that follow this structure: `$account/$region/$environment/$module`. See [gruntwork-io/terragrunt-infrastructure-live-example](https://github.com/gruntwork-io/terragrunt-infrastructure-live-example)
for an example of project structure.

This scheme follows these patterns:

- A team has multiple accounts.
- An **account** uses multiple regions (or `_global` for region-less services such as Route 53, IAM, etc).
- A **region** has multiple environments.
- An **environment** has multiple modules run within it.

## Usage

Provided scripts:

> Note: these scripts are designed to be used from an ephemeral build/ci environment.

- `download-terraform`
   > Download terragrunt and/or terragrunt versions to use.
   > Example usage:
   > ```
   > download-terragrunt --terraform 0.11.8 --terragrunt 0.16.7 --bin-dir /bin
   > ```

- `use-terraform`
   > Download terragrunt and/or terragrunt versions to use.
   > Example usage:
   > ```
   > download-terragrunt --terraform 0.11.8 --terragrunt 0.16.7 --bin-dir /bin
   > ```
   > `download-terraform` should be used before this script.

- `plan-terraform`
  > TBD

- `apply-terraform`
  > TBD
