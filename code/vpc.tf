resource "aws_vpc" "main_vpc" {
  cidr_block="10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames= true
  tags = {
    Name = "main_vpc"
  }
}


//2.create subnet

//varaiable define
variable "vpc_availability_zones"{
    type = list(string)
    description = "Availability Zones"
    default = ["us-east-1a","us-east-1b"]
}

#Setup public subnet
resource "aws_subnet" "tf_public_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  #map_public_ip_on_launch = "true"
  //execute this block 2 times for each az
  count=length(var.vpc_availability_zones)
  cidr_block = cidrsubnet(aws_vpc.main_vpc.cidr_block,8,count.index+1)
  /*
  VPC CIDR Block  10.0.0.0/16
  subnet1 - cidrsubnet(10.0.0.0/16,8,0+1)  --> 10.0.1.0/24
  subnet2 - cidrsubnet(10.0.0.0/16,8,1+1)  --> 10.0.2.0/24
  
  */
  
  availability_zone = element(var.vpc_availability_zones, count.index)

  tags = {
    Name = "tf_public_subnet_${count.index+1}"
  }
}

#Setup private subnet
resource "aws_subnet" "tf_private_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  //execute this block 2 times for each az
  count=length(var.vpc_availability_zones)
  cidr_block = cidrsubnet(aws_vpc.main_vpc.cidr_block,8,count.index+3)
  /*
  VPC CIDR Block  10.0.0.0/16
  subnet1 - cidrsubnet(10.0.0.0/16,8,0+3)  --> 10.0.3.0/24
  subnet2 - cidrsubnet(10.0.0.0/16,8,1+3)  --> 10.0.4.0/24
  */
  
  availability_zone = element(var.vpc_availability_zones, count.index)

  tags = {
    Name = "tf_private_subnet_${count.index+1}"
  }
}

//Setup Internet Gateway
resource "aws_internet_gateway" "igw_vpc" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "Internet Gateway"
  }
}


#Route table for public subnet --> will use IGW
resource "aws_route_table" "public_subnet_rt" {
  vpc_id = aws_vpc.main_vpc.id

 //any instance in the public subnet can communicate with the internet.
  route {
    cidr_block = "0.0.0.0/0"                                         //from
    gateway_id = aws_internet_gateway.igw_vpc.id   //to destination
  }

  tags = {
    Name = "rt_public_subnet"
  }
}

#Attaching subnets to certain tables
resource "aws_route_table_association" "public_subnet_association" {
  route_table_id = aws_route_table.public_subnet_rt.id
  count=length(var.vpc_availability_zones)
  subnet_id = element(aws_subnet.tf_public_subnet[*].id,count.index)
  depends_on = [aws_subnet.tf_public_subnet,aws_route_table.public_subnet_rt]
}


#Elastic IP  
resource "aws_eip" "nat_eip" {
  count  = length(var.vpc_availability_zones)
  domain = "vpc"
  
  depends_on = [aws_internet_gateway.igw_vpc]
}

# Create the NAT Gateway in the Public Subnet
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip[count.index].id   # Each NAT Gateway gets its own EIP
  count         = length(var.vpc_availability_zones)
  subnet_id     = element(aws_subnet.tf_public_subnet[*].id, count.index)
  
  tags = {
    Name = "NAT_Gateway_${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.igw_vpc, aws_eip.nat_eip]
}


#Route table for private subnet --> will use Subnet  (odam LB)
resource "aws_route_table" "private_subnet_rt" {
  vpc_id = aws_vpc.main_vpc.id
  count  = length(var.vpc_availability_zones)

  route {
    cidr_block = "0.0.0.0/0"                         
    gateway_id = element(aws_nat_gateway.nat_gateway[*].id, count.index)
  }

  tags = {
    Name = "rt_private_subnet_${count.index + 1}"
  }
}


#Attaching subnets to certain tables
resource "aws_route_table_association" "private_subnet_association" {
  route_table_id = aws_route_table.private_subnet_rt[count.index].id
  count=length(var.vpc_availability_zones)
  subnet_id = element(aws_subnet.tf_private_subnet[*].id,count.index)
  depends_on = [aws_subnet.tf_private_subnet,aws_route_table.private_subnet_rt]
}

