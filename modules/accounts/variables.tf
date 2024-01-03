variable "aws_organization_unit_id" {
  type = string
}

variable "environments" {
  type = map(object({
    name = string,
    short_name = string,
    owner_email = string
}))
}

