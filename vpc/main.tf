##################################################################
##                       VPC Creation                           ##
##################################################################
resource "aws_vpc" "ctops-vpc" {
  cidr_block           = var.cidr_block
  instance_tenancy     = var.instance_tenancy
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
   tags = merge(
    { "Name" = title(var.name) },
    var.tags,
    var.vpc_tags,
  )
}

#################################################################
#                 Public Subnets Creation                      ##
#################################################################
resource "aws_subnet" "ctops-public-subnet" {
  count                   = length(var.azs)
  vpc_id                  = aws_vpc.ctops-vpc.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true
  tags = merge(
    { Name    = title("${var.name}-${var.public_subnets_name[count.index]}-${count.index + 1}") },
    var.tags,
    var.vpc_tags,
  )
}

################################################################
##                      IGW Creation                           ##
################################################################
resource "aws_internet_gateway" "ctops-igw" {
  vpc_id = aws_vpc.ctops-vpc.id
  tags = merge(
    { "Name" = var.name },
    var.tags,
    var.vpc_tags,
  )
  depends_on = [aws_vpc.ctops-vpc]
}

#################################################################
#                 Public Route Table                           ##
#################################################################
resource "aws_route_table" "ctops-public-route-table" {
  vpc_id = aws_vpc.ctops-vpc.id
  route {
    cidr_block = var.internet-cidr
    gateway_id = aws_internet_gateway.ctops-igw.id
  }
  tags = merge(
    { "Name" = title("${var.name}-Public Route Table") },
    var.tags,
    var.vpc_tags,
  )
  depends_on = [aws_vpc.ctops-vpc, aws_subnet.ctops-public-subnet]
}

#################################################################
#    Public Route Table Asscioation with Public Subnets        ##
#################################################################
resource "aws_route_table_association" "ctops-public-subnet-asscioations" {
  count          = length(var.azs)
  subnet_id      = element(aws_subnet.ctops-public-subnet[*].id, count.index)
  route_table_id = aws_route_table.ctops-public-route-table.id
}


#################################################################
#                 Private Subnets Creation                      ##
#################################################################
resource "aws_subnet" "ctops-private-subnet" {
  count                   = var.enable_private ? length(var.azs) : 0
  vpc_id                  = aws_vpc.ctops-vpc.id
  cidr_block              = var.private-subnet[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = false
  tags = merge(
    { Name    = title("${var.name}-private-Subnet-${count.index + 1}") },
    var.tags,
    var.vpc_tags,
  )
}


##################################################################
##                         EIP Creation                         ##
##################################################################
resource "aws_eip" "ctops-eip" {
count                   = var.enable_private ? 1 : 0
  domain = "vpc"
  tags = merge(
    { Name    = title("${var.name}-eip}") },
    var.tags,
    var.vpc_tags,
  )
}
##################################################################
##                    NAT Gateway Creation                      ##
##################################################################
resource "aws_nat_gateway" "ctops-nat" {
count = var.enable_private ? 1 : 0
  allocation_id = aws_eip.ctops-eip[0].id
  subnet_id     = aws_subnet.ctops-private-subnet[0].id
  tags = merge(
    { Name    = title("${var.name}-Nat}") },
    var.tags,
    var.vpc_tags,
  )
  depends_on = [aws_internet_gateway.ctops-igw]
}
##################################################################
##                 Private Route Table                           ##
##################################################################
resource "aws_route_table" "ctops-private-route-table" {
  count                   = var.enable_private ? 1 : 0
  vpc_id = aws_vpc.ctops-vpc.id
  route {
    cidr_block = var.internet-cidr
    gateway_id = aws_nat_gateway.ctops-nat[0].id
  }
  tags = merge(
    { "Name" = title("${var.name}-Private Route Table") },
    var.tags,
    var.vpc_tags,
  )
}
##################################################################
##    Private Route Table Asscioation with Private Subnets      ##
##################################################################
resource "aws_route_table_association" "ctops-private-subnet-asscioations" {
   count                   = var.enable_private ? length(var.azs) : 0
  subnet_id      = element(aws_subnet.ctops-private-subnet[*].id, count.index)
  route_table_id = aws_route_table.ctops-private-route-table[0].id
}