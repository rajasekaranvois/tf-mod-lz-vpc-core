# Allow the Operations account access to this account
resource "aws_iam_role" "vfde_vpc_flow_role" {
  name = "vfde-vpc-flow-role-${local.random_id}"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# Policy for VPC Flow Logs Role
resource "aws_iam_role_policy" "vfde_vpc_flow_log_role_policy" {
  name = "vfde-vpc-flow-log-role-policy"
  role = aws_iam_role.vfde_vpc_flow_role.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
POLICY
}