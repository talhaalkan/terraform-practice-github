provider "aws" {
region = "us-east-1"
access_key = ""
secret_key = ""
}

# Bir VPC oluşturdum

resource "aws_vpc" "First-Terraform-VPC" {  
  cidr_block = "10.0.0.0/16"  # Default olarak Terraform dökümanındaki CIDR blogunu aldım
  enable_dns_hostnames = true  # DNS adresini otamatik ataması için "true" yaptım
  tags = {
    Name = "First-Terraform-VPC"  # tag ekledim
  }
}

# Bir subnet oluşturdum

resource "aws_subnet" "First-Terraform-Subnet" {  
  vpc_id     = aws_vpc.First-Terraform-VPC.id     # Bu subneti oluşturduğum VPC ye ekledim yani refere ettim.

# Refere işleminde vpc_id kısmında refere ederken önce refere etmek istediğiniz servisin adını "aws_vpc", 
# Sonra sizin vpc nin adı "First-Terraform-VPC", sonra "id" kısmını ekliyorsunuz

  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true  # Public IPv4 address i otomatik vermesi için "true" yaptım
  availability_zone = "us-east-1a"  # AZ yi belirledim
  tags = {
    Name = "First-Terraform-Subnet"  # tag ekledim
  }
}

# İnternet Gateways oluşturdum

resource "aws_internet_gateway" "First-Terraform-gw" { 
  vpc_id = aws_vpc.First-Terraform-VPC.id  # Yine bu I-G yi oluşturduğum VPC ye ekledim yani refere ettim.

  tags = {
    Name = "First-Terraform-gw"  # tag ekledim
  }
}

# Bir VPC oluşurken Default bir route table oluşturulur. Bende oluşan Default route table kısmına 
# İnternete çıkabilmesi için I-G yi route table a tanımladım ve CIDR bloğunu 0.0.0.0/0 yaptım

resource "aws_default_route_table" "First-Terraform-Default-RT" {  
  default_route_table_id = aws_vpc.First-Terraform-VPC.default_route_table_id  # Yine VPC yi refere ettim

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.First-Terraform-gw.id # I-G yi refere ettim
  }
}

# Route table I-G ile internete çıkıyor ama içerisinde subnetimiz olmadığı için işe yaramaz
# Default route table a oluşturduğum subneti ekledim

resource "aws_route_table_association" "First-Terraform-ASSO" {
  subnet_id      = aws_subnet.First-Terraform-Subnet.id  # Subneti refere ettim
  route_table_id = aws_default_route_table.First-Terraform-Default-RT.id  # Route table refere ettim
}

# Bir Security Gorup oluşturdum ve HTTP"80"/SSH"22" portlarına açtım
# Aynı VPC içinde olması gerekir 


resource "aws_security_group" "First-Terraform-Sec-Grp" {
  name        = "First-Terraform-Sec-Grp"
  description = "First-Terraform-Sec-Grp"
  vpc_id = aws_vpc.First-Terraform-VPC.id  # VPC yi refere ettim
  
# giriş portlarını belirledim

  ingress {
    description      = "First-Terraform-HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "First-Terraform-SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

# çıkış portunu her yere açtım

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "First-Terraform-Sec-Grp-HTTP-SSH"  # tag ekledim
  }
}

#  EC2 oluşturdum 
#  Aynı VPC altındaki Subnette olmalı
#  Security Group olmalı
#  User data eklenmeli
resource "aws_instance" "First-Terraform-EC2" { 
  ami = "ami-09d3b3274b6c5d4aa"  # AMI yazdım
  instance_type = "t2.micro"
  key_name = "First_Key"
  availability_zone = "us-east-1a"
  subnet_id = aws_subnet.First-Terraform-Subnet.id  # Subneti refere ettim
  vpc_security_group_ids = [aws_security_group.First-Terraform-Sec-Grp.id]  # sec. grp refere ettim
  user_data = <<EOF
              #!/bin/bash 
              sudo yum update -y
              sudo yum install python3 -y
              sudo pip3 install flask
              cd /home/ec2-user
              wget https://raw.githubusercontent.com/Kaya-Y/friends-projects/main/Project-001-Roman-Numerals-Converter/app.py
              mkdir templates && cd templates
              wget https://raw.githubusercontent.com/Kaya-Y/friends-projects/main/Project-001-Roman-Numerals-Converter/templates/index.html
              wget https://raw.githubusercontent.com/Kaya-Y/friends-projects/main/Project-001-Roman-Numerals-Converter/templates/result.html
              cd ..
              sudo python3 app.py
              EOF
  tags = {
      Name = "First-Terraform-EC2"
  }
}

# Ne kadar açıklayıcı oldu bilmiyorum ama elden geldiğince yazmaya çalıştım umarım faydalı olur 