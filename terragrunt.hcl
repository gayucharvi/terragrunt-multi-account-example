locals {
  common_vars = yamldecode(file("common_vars.yaml"))
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  account_name                  = local.environment_vars.locals.account_name
  account_id                    = local.environment_vars.locals.aws_account_id
  environment                   = local.environment_vars.locals.environment
  aws_profile                   = local.environment_vars.locals.aws_profile
  aws_region                    = local.region_vars.locals.aws_region
  terraform_state_bucket_prefix = local.common_vars.terraform_state_bucket_prefix
}

# Set AWS profile by default
terraform {
  extra_arguments "aws_profile" {
    commands = [
      "init",
      "apply",
      "refresh",
      "import",
      "plan",
      "taint",
      "untaint"
    ]

    env_vars = {
      AWS_PROFILE = "${local.aws_profile}"
    }

  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"
  allowed_account_ids = ["${local.account_id}"]
  profile = "${local.aws_profile}"
}
EOF
}

remote_state {
  backend = "s3"
  config = {
    encrypt        = true
    bucket         = "${local.terraform_state_bucket_prefix}-${local.environment}-${local.aws_region}-terraform-state"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.aws_region
    dynamodb_table = "terraform-locks"
    profile        = "${local.aws_profile}"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}


inputs = merge(
  local.region_vars.locals,
  local.environment_vars.locals,
  local.common_vars,
)


