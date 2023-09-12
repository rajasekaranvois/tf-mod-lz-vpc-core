locals {
  random_id = random_string.vfde_random.id
}

# Declare the data sources

# AWS Account 
data "aws_caller_identity" "vfde_current" {}

# Availability Zones in given region
data "aws_availability_zones" "vfde_azs" {
  state = "available"
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# Generates randomness
resource "random_string" "vfde_random" {
  length  = 8
  special = false
  upper   = false
}