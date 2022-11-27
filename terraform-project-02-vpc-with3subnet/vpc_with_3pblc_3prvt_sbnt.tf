#vpc oluşturma 3 public 3 private

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR values"
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}
variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private Subnet CIDR values"
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}
variable "availability_zones" {
  type        = list(string)
  description = "Availability Zones"
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}
resource "aws_vpc" "tf-vpc-proje" {
  cidr_block = "10.0.0.0/16"
 tags = {
   Name = "tf-VPC-proje"
 }
}
resource "aws_subnet" "tf-public-subnet-vpc" {
  vpc_id            = aws_vpc.tf-vpc-proje.id
  count             = length(var.public_subnet_cidrs)
  cidr_block        = element(var.public_subnet_cidrs, count.index)
  availability_zone = element(var.availability_zones, count.index)
  tags = {
    Name = "tf-public-subnet-${count.index + 1}-vpc"
  }
}
resource "aws_subnet" "tf-private-subnet-vpc" {
  vpc_id            = aws_vpc.tf-vpc-proje.id
  count             = length(var.private_subnet_cidrs)
  cidr_block        = element(var.private_subnet_cidrs, count.index)
  availability_zone = element(var.availability_zones, count.index)
  tags = {
    Name = "tf-private-subnet-${count.index + 1}-vpc"
  }
}
resource "aws_internet_gateway" "tfIgateway" {
  vpc_id = aws_vpc.tf-vpc-proje.id
  tags = {
    Name = "tf-vpc-IGW"
  }
}
resource "aws_route_table" "tf-public-route-table" {
  vpc_id = aws_vpc.tf-vpc-proje.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tfIgateway.id
  }
  tags = {
    Name = "tf-public-route-table"
  }
}
#public subnetleri igw üzerinden webe çıkarmak için ilişkilendirme. 
#vpc nin default route table'ı localde çalışır.

resource "aws_route_table_association" "PublicSubnet_association" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = element(aws_subnet.tf-public-subnet-vpc[*].id, count.index)
  route_table_id = aws_route_table.tf-public-route-table.id
}