locals {
  # Subnets
  public_subnet   = var.public_subnets   # 1) public
  private_subnet  = var.private_subnets  # 2) private
  internal_subnet = var.internal_subnets # 3) internal
  
  # 1) Identify which subnets have the same subnet bits with public
  subnet_count_per_public = local.public_subnet.subnet_count + (local.public_subnet.subnet_bits == local.private_subnet.subnet_bits ? local.private_subnet.subnet_count : 0) + (local.public_subnet.subnet_bits == local.internal_subnet.subnet_bits ? local.internal_subnet.subnet_count : 0)

  # 2) Identify which subnets have the same subnet bits with private
  subnet_count_per_private = local.private_subnet.subnet_count + (local.private_subnet.subnet_bits == local.public_subnet.subnet_bits ? local.public_subnet.subnet_count : 0) + (local.private_subnet.subnet_bits == local.internal_subnet.subnet_bits ? local.internal_subnet.subnet_count : 0)

  # 3) Identify which subnets have the same subnet bits with internal
  subnet_count_per_internal = local.internal_subnet.subnet_count + (local.internal_subnet.subnet_bits == local.public_subnet.subnet_bits ? local.public_subnet.subnet_count : 0) + (local.internal_subnet.subnet_bits == local.private_subnet.subnet_bits ? local.private_subnet.subnet_count : 0)
  
  # 1) The subnet offset for public subnets (rounding the neareast smaller number multiple of ten)
  public_subnet_offset = local.subnet_count_per_public > 0 ? ((pow(2, var.public_subnets.subnet_bits) - 1) / local.subnet_count_per_public) > 10 ? floor(((pow(2, var.public_subnets.subnet_bits) - 1) / local.subnet_count_per_public) / 10) * 10 : floor(((pow(2, var.public_subnets.subnet_bits) - 1) / local.subnet_count_per_public)) : 0

  # 2) The subnet offset for private subnets (rounding the neareast smaller number multiple of ten)
  private_subnet_offset = local.subnet_count_per_private > 0 ? ((pow(2, var.private_subnets.subnet_bits) - 1) / local.subnet_count_per_private) > 10 ? floor(((pow(2, var.private_subnets.subnet_bits) - 1) / local.subnet_count_per_private) / 10) * 10 : floor(((pow(2, var.private_subnets.subnet_bits) - 1) / local.subnet_count_per_private)) : 0

  # 3) The subnet offset for internal subnets (rounding the neareast smaller number multiple of ten)
  internal_subnet_offset = local.subnet_count_per_internal > 0 ? ((pow(2, var.internal_subnets.subnet_bits) - 1) / local.subnet_count_per_internal) > 10 ? floor(((pow(2, var.internal_subnets.subnet_bits) - 1) / local.subnet_count_per_internal) / 10) * 10 : floor(((pow(2, var.internal_subnets.subnet_bits) - 1) / local.subnet_count_per_internal)) : 0

  # 1) The public subnet step
  public_subnet_step = 0

  # 2) The private subnet step
  private_subnet_step = (local.private_subnet.subnet_bits == local.public_subnet.subnet_bits ? local.public_subnet.subnet_count : 0)

  # 3) The internal subnet step
  internal_subnet_step = (local.internal_subnet.subnet_bits == local.public_subnet.subnet_bits ? local.public_subnet.subnet_count : 0) + (local.internal_subnet.subnet_bits == local.private_subnet.subnet_bits ? local.private_subnet.subnet_count : 0)

  az_zone_ids = data.aws_availability_zones.vfde_azs.zone_ids
  env_prefix = "${var.env_prefix}-${data.aws_caller_identity.vfde_current.account_id}"
  nat_gateway_count = var.single_nat_gateway ? 1 : min(length(local.az_zone_ids), local.public_subnet.subnet_count, local.private_subnet.subnet_count)
}

#########################################################
# VPC Section
#########################################################
resource "aws_vpc" "vfde_main" {
  cidr_block = var.vpc_cidr_block["main"]
    
  enable_dns_hostnames = var.default_vpc_enable_dns_hostnames
  enable_dns_support   = var.default_vpc_enable_dns_support
  assign_generated_ipv6_cidr_block = var.assign_generated_ipv6_cidr_block

  tags = merge(
    var.common_tags,
    {
      "Name" = "${local.env_prefix}-main"
    }
  )
}

# Default Security Group
resource "aws_default_security_group" "default" {
  # Remove default ingress and egress rules from default security group. Implemented to align with PCS security rule
  vpc_id = aws_vpc.vfde_main.id
  
  tags = merge(
    var.common_tags,
    {
      "Name" = "VPC Default Security Group (Do not use)"
    }
  )
}

# VPC Flow Logs
resource "aws_flow_log" "vfde_vpc_flow_log" {
  iam_role_arn    = aws_iam_role.vfde_vpc_flow_role.arn
  log_destination = aws_cloudwatch_log_group.vfde_vpc_flow_log_group.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.vfde_main.id

  tags = merge(
    var.common_tags,
    {
      "Name" = "${local.env_prefix}-flow-log"
    }
  )
}


##########################################################
# Subnet Section
##########################################################
# Public Subnet
resource "aws_subnet" "vfde_public_subnets" {
  count = local.public_subnet.subnet_count > 0 ? local.public_subnet.subnet_count : 0
  
  vpc_id = aws_vpc.vfde_main.id
  cidr_block = cidrsubnet(var.vpc_cidr_block["main"], local.public_subnet.subnet_bits, local.public_subnet_offset * (count.index + 1 + local.public_subnet_step))
  availability_zone_id = local.az_zone_ids[count.index % length(local.az_zone_ids)]

  tags = merge(
    var.common_tags,
    {
      "Name" = "${local.env_prefix}-${local.public_subnet["name"]}-${local.az_zone_ids[count.index % length(local.az_zone_ids)]}",
      "NetworkZone" = local.public_subnet["network_zone"]
    }
  )
}

# Private Subnet
resource "aws_subnet" "vfde_private_subnets" {
  count = local.private_subnet.subnet_count > 0 ? local.private_subnet.subnet_count : 0
  
  vpc_id = aws_vpc.vfde_main.id
  cidr_block = cidrsubnet(var.vpc_cidr_block["main"], local.private_subnet.subnet_bits, local.private_subnet_offset * (count.index + 1 + local.private_subnet_step))
  availability_zone_id = local.az_zone_ids[count.index % length(local.az_zone_ids)]

  tags = merge(
    var.common_tags,
    {
      "Name" = "${local.env_prefix}-${local.private_subnet["name"]}-${local.az_zone_ids[count.index % length(local.az_zone_ids)]}",
      "NetworkZone" = local.private_subnet["network_zone"]
    }
  )

  depends_on = [aws_subnet.vfde_public_subnets]
}

# Internal Subnet
resource "aws_subnet" "vfde_internal_subnets" {
  count = local.internal_subnet.subnet_count > 0 ? local.internal_subnet.subnet_count : 0
  
  vpc_id = aws_vpc.vfde_main.id
  cidr_block = cidrsubnet(var.vpc_cidr_block["main"], local.internal_subnet.subnet_bits, local.internal_subnet_offset * (count.index + 1 + local.internal_subnet_step))
  availability_zone_id = local.az_zone_ids[count.index % length(local.az_zone_ids)]

  tags = merge(
    var.common_tags,
    {
      "Name" = "${local.env_prefix}-${local.internal_subnet["name"]}-${local.az_zone_ids[count.index % length(local.az_zone_ids)]}",
      "NetworkZone" = local.internal_subnet["network_zone"]
    }
  )

  depends_on = [aws_subnet.vfde_private_subnets]
}

##########################################################
# Subnet Groups Section
##########################################################

resource "aws_db_subnet_group" "vfde_net_internal_subnet_group" {
  count = local.internal_subnet.subnet_count > 0 ? 1 : 0
  name = "${local.env_prefix}-net-internal-subnet-group-${local.random_id}"
  subnet_ids = aws_subnet.vfde_internal_subnets.*.id

  tags = merge(
    var.common_tags,
    {
      "Name" = "${local.env_prefix}-${local.internal_subnet["name"]}-group"
    }
  )
}


##########################################################
# Gateway Section
##########################################################

resource "aws_eip" "vfde_nat_gateway_eip" {
  count = var.enable_nat_gateway ? local.nat_gateway_count : 0
  vpc = true
  
  tags = merge(
    var.common_tags,
    {
      "Name" = "${local.env_prefix}-eip${count.index}"
    }
  )
}

# NAT Gateway
resource "aws_nat_gateway" "vfde_nat_gateway" {
  count = var.enable_nat_gateway ? local.nat_gateway_count : 0
  allocation_id = aws_eip.vfde_nat_gateway_eip[count.index].id
  subnet_id     = aws_subnet.vfde_public_subnets[count.index % local.nat_gateway_count].id
  
  tags = merge(
    var.common_tags,
    {
      "Name" = "${local.env_prefix}-nat-gw-${local.az_zone_ids[count.index % local.nat_gateway_count]}"
    }
  )
  
  depends_on = [aws_internet_gateway.vfde_main_igw]
}

# Internet Gateway
resource "aws_internet_gateway" "vfde_main_igw" {
  count = local.public_subnet.subnet_count > 0 ? 1 : 0
  vpc_id = aws_vpc.vfde_main.id
 
  tags = merge(
    var.common_tags,
    {
      "Name" = "${local.env_prefix}-igw-main-vpc"
    }
  )
}


##########################################################
# Routing Section
##########################################################

# Default Route Table
resource "aws_default_route_table" "vfde_default_route_table" {
  default_route_table_id = aws_vpc.vfde_main.default_route_table_id

  tags = merge(
    var.common_tags,
    {
      "Name" = "Default Route Table"
    }
  )
}

# Public Route Table
resource "aws_route_table" "vfde_net_public_route" {
  count = local.public_subnet.subnet_count > 0 ? 1 : 0
  vpc_id = aws_vpc.vfde_main.id

  tags = merge(
    var.common_tags,
    {
      "Name" = "${local.env_prefix}-rt-${local.public_subnet["name"]}"
    }
  )
}

# IGW Route
resource "aws_route" "vfde_igw_route" {
  count = local.public_subnet.subnet_count > 0 ? 1 : 0
  route_table_id = aws_route_table.vfde_net_public_route[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id   = aws_internet_gateway.vfde_main_igw[0].id
}

# Public Route Table to Public Subnets Association
resource "aws_route_table_association" "vfde_net_public_assoc" {
  count          = local.public_subnet.subnet_count > 0 ? local.public_subnet.subnet_count : 0
  subnet_id      = element(aws_subnet.vfde_public_subnets.*.id , count.index)
  route_table_id = aws_route_table.vfde_net_public_route[0].id
}

# Private Route Table
resource "aws_route_table" "vfde_net_private_route" {
  count = var.enable_nat_gateway ? local.nat_gateway_count : (local.private_subnet.subnet_count > 0 ? 1 : 0)
  vpc_id = aws_vpc.vfde_main.id

  dynamic "route" {
    for_each = var.enable_nat_gateway == true ? [1] : []
    content {
      cidr_block   = "0.0.0.0/0"
      nat_gateway_id   = aws_nat_gateway.vfde_nat_gateway[count.index].id
    }
  }

  tags = merge(
    var.common_tags,
    {
      "Name" = "${local.env_prefix}-rt-${local.private_subnet["name"]}"
    }
  )
}

# NAT Gateway to Private Subnets Association
resource "aws_route_table_association" "vfde_net_private_assoc" {
  count = var.enable_nat_gateway ? local.private_subnet.subnet_count : (local.private_subnet.subnet_count > 0 ? local.private_subnet.subnet_count : 0)
  subnet_id = aws_subnet.vfde_private_subnets[count.index].id
  route_table_id = aws_route_table.vfde_net_private_route[var.enable_nat_gateway ? (var.single_nat_gateway ? 0 : count.index % local.nat_gateway_count) : 0].id
}

# Internal Route Table
resource "aws_route_table" "vfde_net_internal_route" {
  count = local.internal_subnet.subnet_count > 0 ? 1 : 0
  vpc_id = aws_vpc.vfde_main.id

  tags = merge(
    var.common_tags,
    {
      "Name" = "${local.env_prefix}-rt-${local.internal_subnet["name"]}"
    }
  )
}

# Internal Subnets Association
resource "aws_route_table_association" "vfde_net_internal_assoc" {
  count = local.internal_subnet.subnet_count > 0 ? local.internal_subnet.subnet_count : 0
  subnet_id = aws_subnet.vfde_internal_subnets[count.index].id
  route_table_id = aws_route_table.vfde_net_internal_route[0].id
}

##########################################################
# Tagging Default Network ACL
##########################################################
resource "aws_default_network_acl" "vfde_default_network_acl" {
  default_network_acl_id = aws_vpc.vfde_main.default_network_acl_id

  subnet_ids = concat(aws_subnet.vfde_private_subnets.*.id, aws_subnet.vfde_public_subnets.*.id, aws_subnet.vfde_internal_subnets.*.id)

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  lifecycle {
    ignore_changes = [subnet_ids]
  }

  tags = merge(
    var.common_tags,
    {
      "Name" = "Default Route Table"
    }
  )
}
