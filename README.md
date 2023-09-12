# tf-mod-lz-vpc-core

| Version|Author|Email|
|---|---|---|
|1.0|Alexander Galstyan|alexander.galstyan@vodafone.com|

<br></br>
#### **SUMMARY**
----------------
This module is used create Landing Zone core VPC components in a AWS Account for a specific region.

<br></br>
#### **TERRAFORM VERSIONS**
Currently module requires Terraform version `~> 1.0.2`.

> :grey_exclamation: This may be a subject to change in the future.

<br></br>
#### **USAGE**
--------------
There are several parameters required in order to successfully build tf-mod-lz-vpc-core components.


```terraform
#########################################################
# tf-mod-lz-vpc-core Module
#########################################################
module "tf-mod-lz-vpc-core" {
  source                = "./tf-mod-lz-vpc-core"
  vpc_cidr_block        = <vpc_cidr_block>            # VPC CIDR Block (Required)
  public_subnets        = {                           # Public Subnet (Required)
                            "name" : "net-pub",       # Subnet Name
                            "subnet_count" : 3,       # Count of desired subnets
                            "subnet_bits" : 8,        # Number of additional bits with which to extend the prefix
                            "network_zone" : "DMZ"    # Network Zone 
                          }
  private_subnets       = {                           # Private Subnet (Required)
                            "name" : "net-priv",  
                            "subnet_count" : 4,
                            "subnet_bits" : 5,
                            "network_zone" : "M"
                          }
  internal_subnets      = {                           # Internal Subnet (Required)
                            "name" : "net-internal",
                            "subnet_count" : 3,
                            "subnet_bits" : 8,
                            "network_zone" : "M"
                          }
  enable_nat_gateway               = true             # Whether NAT Gateway enabled or not (Optional. Default: true)
  single_nat_gateway               = false            # Whether to provision a single shared NAT Gateway across all private networks (Optional. Default: false)
  default_vpc_enable_dns_support   = true             # Whether or not the VPC has DNS support (Optional. Default: true)
  default_vpc_enable_dns_hostnames = true             # Whether or not the VPC has DNS hostname support (Optional. Default: true)
  assign_generated_ipv6_cidr_block = false            # Requests an Amazon-provided IPv6 CIDR block with a /56 prefix length for the VPC (Optional. Default: false)
  common_tags                      = <tags>           # Tags from calling module (Optional)
}
```
The subnet block:
```json
{
  "name" : "net-internal",
  "subnet_count" : 3,
  "subnet_bits" : 8,
  "network_zone" : "M"
}
```
represents the 'single type' of subnets:
> ***<ins>public</ins>***  : internet connectivity via internet gateway is allowed\
> ***<ins>private</ins>*** : internet connectivity via NAT gateway is allowed\
> ***<ins>internal</ins>***: no internet connectivity is allowed

<br></br>
The subnet block attributes are described in the table below:

Attribute      | Description
---------------| ------------------------------
`name`         | The logical name of the subnet
`subnet_count` | The number of subnet to produce
`subnet_bits`  | Number of additional bits with which to extend the prefix
`network_zone` | Network zone

where `subnet_bits` attribute in conjunction with `subnet_count` attribute allows to produce required number of subnets within given prefix extension distributed evenly.

For example the subnet block:

```json
{
  "name" : "net-internal",
  "subnet_count" : 9,
  "subnet_bits" : 8,
  "network_zone" : "M"
}
```
for the given `vpc_cidr_block` = "10.181.0.0/16"\
will produce the following list of CIDR blocks:

> 10.181.20.0/24\
> 10.181.40.0/24\
> 10.181.60.0/24\
> ...and so on\
> 10.181.180.0/24
>
> i.e. with offset 20
> or to be more specific:\
> 2^8/9 rounded the nearest smallest number multiply of 10 (if exists)

<br></br>
#### **MODULE OUTPUT**
Module creates following resources:

- VPC
- VPC Flow Logs
- Public Subnets (if enabled via `subnet_count` attribute)
- Private Subnets (if enabled via `subnet_count` attribute)
- Internal Subnets (if enabled via `subnet_count` attribute)
- Internet Gateway (if Public Subnets are enabled)
- NAT Gateway (if enabled: single or per AZ). More strictly the count of NAT Gateway is `min([number of available AZs], [number of public subnets], [number of private subnets])`
- Route Tables (Default, Public Subnet->IGW, Private Subnet->NAT, Internal Subnet->[]) and corresponding subnet associations (if enabled)
  - Route Table for public, private, internal subnets and those subnet associations are created independently of creation of IGW or NAT.
- Default Route Table (Tagging only)
- RDS DB Subnet Group
- EIPs (NAT associations, if NAT enabled)
- Network ACL

> :grey_exclamation: This may be a subject to change in the future.


Module will output references to the created resources, which may be required in the calling module.

Among others the following references will be returned:

Reference        | Description
-----------------| ------------------------------
`vpc_id`         | Id of created VPC
`public_net`     | Ids of the produced public subnets
`private_net`    | Ids of the produced private subnets
`internal_net`   | Ids of the produced internal subnets
`db_subnet_group`| Id of the created RDS DB subnet group
`public_route_table_ids`  | Ids of created public route tables
`private_route_table_ids` | Ids of created private route tables
`internal_route_table_ids`| Ids of created internal route tables
`public_net_cidr_blocks`  | Public subnet CIDR blocks
`private_net_cidr_blocks` | Private subnet CIDR blocks
`internal_net_cidr_blocks`| Internal subnet CIDR blocks

<br></br>
#### **SUPPORT & LIMITATIONS**
--------------
