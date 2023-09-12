# Global
output azs {
  value = zipmap(data.aws_availability_zones.vfde_azs.zone_ids, data.aws_availability_zones.vfde_azs.names)
}

# VPC
output vpc_id {
  value = aws_vpc.vfde_main.id
}

output vpc_cidr_block {
  value = aws_vpc.vfde_main.cidr_block
}

# Subnets
output public_net_ids {
  value = aws_subnet.vfde_public_subnets.*.id
}

output public_net_cidr_blocks {
  value = aws_subnet.vfde_public_subnets.*.cidr_block
}

output private_net_ids {
  value = aws_subnet.vfde_private_subnets.*.id
}

output private_net_cidr_blocks {
  value = aws_subnet.vfde_private_subnets.*.cidr_block
}

output internal_net_ids {
  value = aws_subnet.vfde_internal_subnets.*.id
}

output internal_net_cidr_blocks {
  value = aws_subnet.vfde_internal_subnets.*.cidr_block
}

output db_subnet_group {
  value = aws_db_subnet_group.vfde_net_internal_subnet_group.*.id
}

output private_route_table_ids {
  value = aws_route_table.vfde_net_private_route.*.id
}

output public_route_table_ids {
  value = aws_route_table.vfde_net_public_route.*.id
}

output internal_route_table_ids {
  value = aws_route_table.vfde_net_internal_route.*.id
}

output default_route_table_id {
  value = aws_vpc.vfde_main.default_route_table_id
}

output subnets {
  value = {
    for subnet in flatten(tolist([length(aws_subnet.vfde_public_subnets.*) > 0 ? aws_subnet.vfde_public_subnets.* : [] , length(aws_subnet.vfde_private_subnets.*) > 0 ? aws_subnet.vfde_private_subnets.* : [], length(aws_subnet.vfde_internal_subnets.*) > 0 ? aws_subnet.vfde_internal_subnets.* : []])): 
      subnet.id => subnet.cidr_block
  }
}

# Test
output subnet_count {
    value = tomap({
        # 1) Identify which subnets have the same subnet bits with public
        "subnet_count_per_public" = local.subnet_count_per_public

        # 2) Identify which subnets have the same subnet bits with private
        "subnet_count_per_private" = local.subnet_count_per_private

        # 3) Identify which subnets have the same subnet bits with internal
        "subnet_count_per_internal" = local.subnet_count_per_internal
        
        # 1) The subnet offset for public subnets (rounding the neareast smaller number multiple of ten)
        "public_subnet_offset" = local.public_subnet_offset

        # 2) The subnet offset for private subnets (rounding the neareast smaller number multiple of ten)
        "private_subnet_offset" = local.private_subnet_offset

        # 3) The subnet offset for internal subnets (rounding the neareast smaller number multiple of ten)
        "internal_subnet_offset" = local.internal_subnet_offset

        # 1) The public subnet step
        "public_subnet_step" = local.public_subnet_step

        # 2) The private subnet step
        "private_subnet_step" = local.private_subnet_step

        # 3) The internal subnet step
        "internal_subnet_step" = local.internal_subnet_step
    })
}