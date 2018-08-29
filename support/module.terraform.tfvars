# This file is placed in the module directory, and must be parsed before executing.
#
# ./$account/$region/$environment/$module
#                                   └─ here

terragrunt = {
  terraform {
    source = "__module_path_or_url__"
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}
