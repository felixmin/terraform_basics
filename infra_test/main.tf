provider "aws" {
    profile = "default"
    region = "eu-central-1"
}

resource "aws_vpc" "my_vpc" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = "my_vpc"
        Project = "terraform-basics"
    }
}

resource "aws_subnet" "public_subnet" {
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = "10.0.0.0/24"
    tags = {
        Name = "public_subnet"
        Project = "terraform-basics"
    }
}

resource "aws_subnet" "private_subnet" {
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = "10.0.1.0/24"
    tags = {
        Name = "private_subnet"
        Project = "terraform-basics"
    }
}

resource "aws_internet_gateway" "my_igw" {
    vpc_id = aws_vpc.my_vpc.id
    tags = {
        Name = "my_igw"
        Project = "terraform-basics"
    }
}

resource "aws_eip" "rag_nat_eip" {
  vpc = true


  tags = {
    Name = "rag_nat_eip"
    Project = "terraform-basics"
  }
}

resource "aws_nat_gateway" "my_nat" {
    allocation_id = aws_eip.rag_nat_eip.id
    subnet_id = aws_subnet.public_subnet.id
    connectivity_type = "public"
    tags = {
        Name = "my_nat"
        Project = "terraform-basics"
    }
}

resource "aws_route_table" "public_route_table" {
    vpc_id = aws_vpc.my_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.my_igw.id
    }
    tags = {
        Name = "public_route_table"
        Project = "terraform-basics"
    }
}

resource "aws_route_table_association" "public_route_table_association" {
    subnet_id = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table" "private_route_table" {
    vpc_id = aws_vpc.my_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.my_nat.id
    }
    tags = {
        Name = "private_route_table"
        Project = "terraform-basics"
    }
}

resource "aws_route_table_association" "private_route_table_association" {
    subnet_id = aws_subnet.private_subnet.id
    route_table_id = aws_route_table.private_route_table.id
}

resource "aws_key_pair" "deployer_key" {
  key_name   = "tf-basics-deployer-key"
  public_key = file("/Users/f.minzenmay/data/rag-chatbot/my-key2.pub")
  tags = {
    Name = "tf-basics-deployer_key"
    Project = "terraform-basics"
  }
}

resource "aws_security_group" "allow_everything" {
  name        = "allow_everything"
  description = "Allow traffic"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_everything"
    Project = "terraform-basics"
  }
}


resource "aws_instance" "terraform_basics_private_instance" {
    subnet_id = aws_subnet.private_subnet.id
    ami = "ami-0793a9d76284434e5"
    instance_type = "t2.micro"
    key_name = aws_key_pair.deployer_key.key_name
    associate_public_ip_address = false
    vpc_security_group_ids = [aws_security_group.allow_everything.id]
    tags = {
        Name = "private_instance"
        Project = "terraform-basics"
    }
}

resource "aws_instance" "terraform_basics_public_instance" {
    subnet_id = aws_subnet.public_subnet.id
    ami = "ami-0793a9d76284434e5"
    instance_type = "t2.micro"
    key_name = aws_key_pair.deployer_key.key_name
    associate_public_ip_address = true
    vpc_security_group_ids = [aws_security_group.allow_everything.id]
    tags = {
        Name = "public_instance"
        Project = "terraform-basics"
    }
}

