# Environment prefix
variable env_prefix {
  type = string
  default = "vfde"
}

# VPC
variable vpc_cidr_block {
  description = "VPC CIDR Block"
  type = map(string)
  validation {
    condition = (
      can(var.vpc_cidr_block) && length(var.vpc_cidr_block["main"]) > 0
    )
    error_message = "1) VPC CIDR Block is required."
  }
}

variable default_vpc_enable_dns_support {
  description = "Whether or not the VPC has DNS support"
  type = bool
  default = true
}
  
variable default_vpc_enable_dns_hostnames {
  description = "Whether or not the VPC has DNS hostname support"
  type = bool
  default = true
}

variable assign_generated_ipv6_cidr_block {
  description = "Requests an Amazon-provided IPv6 CIDR block with a /56 prefix length for the VPC"
  type = bool
  default = false
}

# CIDR block of public subnets
variable public_subnets {
  description = "CIDR blocks and network zone of public subnets"
  type = map

  validation {
    condition = (
      can(var.public_subnets["subnet_bits"]) && can(var.public_subnets["subnet_count"]) &&
      can(cidrsubnet("10.0.0.0/16", var.public_subnets["subnet_bits"], 0)) &&
      pow(2, var.public_subnets["subnet_bits"]) - 1 > var.public_subnets["subnet_count"]
    )
    error_message = "1) Required 'subnet_bits' and/or 'subnet_count' variable are not set. \n2) Insufficient address space or prefix extension of 'subnet_bits' will not accommodate a subnet."
  }
}

# CIDR block of private subnets
variable private_subnets {
  description = "CIDR blocks and network zone of private subnets"
  type = map

  validation {
    condition = (
      can(var.private_subnets["subnet_bits"]) && can(var.private_subnets["subnet_count"]) &&
      can(cidrsubnet("10.0.0.0/16", var.private_subnets["subnet_bits"], 0)) &&
      pow(2, var.private_subnets["subnet_bits"]) - 1 > var.private_subnets["subnet_count"]
    )
    error_message = "1) Required 'subnet_bits' and/or 'subnet_count' variable are not set. \n2) Insufficient address space or prefix extension of 'subnet_bits' will not accommodate a subnet."
  }
}

# CIDR block of internal subnets
variable internal_subnets {
  description = "CIDR blocks and network zone of internal subnets"
  type = map

  validation {
    condition = (
      can(var.internal_subnets["subnet_bits"]) && can(var.internal_subnets["subnet_count"]) &&
      can(cidrsubnet("10.0.0.0/16", var.internal_subnets["subnet_bits"], 0)) &&
      pow(2, var.internal_subnets["subnet_bits"]) - 1 > var.internal_subnets["subnet_count"]
    )
    error_message = "1) Required 'subnet_bits' and/or 'subnet_count' variable are not set. \n2) Insufficient address space or prefix extension of 'subnet_bits' will not accommodate a subnet."
  }
}

# Gateways
variable enable_nat_gateway {
  description = "Whether NAT Gateway enabled or not"
  type = bool
  default = true
}

variable single_nat_gateway {
  description = "Whether to provision a single shared NAT Gateway across all private networks"
  type = bool
  default = false
}

# Tags
variable common_tags { default = {} }
