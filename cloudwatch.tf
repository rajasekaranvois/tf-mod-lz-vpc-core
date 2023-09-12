# CloudWatch Log Group for VPC Flos Logs
resource "aws_cloudwatch_log_group" "vfde_vpc_flow_log_group" {
  name = "${local.env_prefix}-vpc-flow-logs-${local.random_id}"
  retention_in_days = "14"

  tags = merge(
    var.common_tags,
    {
      "Name" = "${local.env_prefix}-vpc-flow-logs"
    }
  )
}