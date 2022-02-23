data "aws_ami" "example" {
  most_recent      = true
  owners           = ["self"]

  filter {
    name   = "name"
    values = ["packer-centos7*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


resource "aws_instance" "web" {
  ami           = "ami-04145c8c86d2474c0"     # data.aws_ami.example.id
  instance_type = "t3.micro"
  subnet_id = data.aws_subnet.selected.id

  tags = {
    Name = "Terraform"
  }
}

// output "ami" {
//   value = data.aws_ami.example.id
// }

data "aws_subnet" "selected" {
  availability_zone = "us-east-1a"
  filter {
    name   = "tag:Name"
    values = ["DEV_Project"]
  }
}