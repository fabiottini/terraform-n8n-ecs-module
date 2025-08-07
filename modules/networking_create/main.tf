# =====================================================================
# Textual diagram of the networking architecture
#
#                +-------------------+
#                |    Internet       |
#                +--------+----------+
#                         |
#                +--------v----------+
#                |  Internet Gateway |
#                +--------+----------+
#                         |
#                +--------v----------+
#                |      VPC          |
#                |   (n8n-vpc)       |
#                +---+-----------+---+
#                    |           |
#        +-----------+           +-----------+
#        |                                   |
# +------v------+                     +------v------+
# | Public Sub  |  ... (n AZs) ...    | Private Sub |
# | n8n-public-0|                     | n8n-private-0|
# +-------------+                     +-------------+
#        |                                   |
# +------v------+                     +------v------+
# | Route Table |                     | Route Table |
# |  (public)   |                     | (private)   |
# +------^------+                     +------^------+
#        |                                   |
# +------v------+                     +------v------+
# | NAT Gateway |<--------------------+  EIP        |
# +-------------+                     +-------------+
#
# Note:
# - Public subnets have direct access to the Internet via the Internet Gateway.
# - Private subnets access the Internet via the NAT Gateway (which has an EIP in the public subnet).
# - Route tables associate subnets with their respective routing rules.
# =====================================================================

resource "aws_vpc" "n8n" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(var.common_tags, { Name = "n8n-vpc" })
}

########################################################################
# Public
########################################################################

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.n8n.id
  tags   = merge(var.common_tags, { Name = "n8n-igw" })
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.n8n.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags = merge(var.common_tags, {
    Name    = "n8n-public-${count.index}"
    public  = "true"
    private = "false"
  })
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.n8n.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-public-route-table"
  })
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

########################################################################
# Private
########################################################################

data "aws_availability_zones" "available" {}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.n8n.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = merge(var.common_tags, {
    Name    = "n8n-private-${count.index}"
    public  = "false"
    private = "true"
  })
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-nat-eip"
  })
}

resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public[0].id
  tags          = merge(var.common_tags, { Name = "n8n-nat" })
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.n8n.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgw.id
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-private-route-table"
  })
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}