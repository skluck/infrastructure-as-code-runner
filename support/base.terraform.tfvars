# This file will be placed within the base of the project (account-level)
#
# ./$account/$region/$environment/$module
#     └─ here

terragrunt = {

  remote_state {

    # This stanza can be customized. Depending on your CI or deployment system.
    # It should contain configuration for your team-wide backend. See backend.tf

    backend = "local"

    config {
      path = "${get_env("TF_STATE_PREFIX", "")}terraform.tfstate"
    }

  }

  # Configure root level variables that all resources can inherit
  terraform {

    after_hook "add_local_backend" {
      commands = ["init", "init-from-module"]
      execute = ["cp", "${get_parent_tfvars_dir()}/backend.tf", "."]
    }

    extra_arguments "derp" {
      commands = [
        # "apply",    # We use tfplans, which conflicts with this
        "console",
        "destroy",
        "import",
        "plan",
        "push",
        "refresh",
        "validate",
      ]

      optional_var_files = [
          "${get_tfvars_dir()}/${find_in_parent_folders("account.tfvars", "ignore")}",
          "${get_tfvars_dir()}/${find_in_parent_folders("region.tfvars", "ignore")}",
          "${get_tfvars_dir()}/${find_in_parent_folders("env.tfvars", "ignore")}",
      ]
    }

  }

}
