# bash -c "$(curl https://bucket-to-check-aws-tasks.s3.amazonaws.com/AWS/scripts/shared_scripts/jenkins_environment.sh

provider "aws" {
  region = "us-east-1"
}

variable "vpc_config" {
  type = map(any)
  default = {
    region          = "us-east-1"
    cluster_version = "1.19"
    jenkins_max_size    = 10
    jenkins_min_size    = 1
    jenkins_desired_capacity = 1
    vpc_cidr      = "10.0.0.0/16"
    public_cidr1  = "10.0.1.0/24"
    public_cidr2  = "10.0.2.0/24"
    public_cidr3  = "10.0.3.0/24"
    private_cidr1 = "10.0.101.0/24"
    private_cidr2 = "10.0.102.0/24"
    private_cidr3 = "10.0.103.0/24"
    image_id      = "ami-04145c8c86d2474c0"
    jenkins_instance_type   = "m5.xlarge"
  }
}

variable "tags" {
  type = map(any)
  default = {
    Name        = "Jenkins"
    Environment = "Jenkins"
    Created_by  = "Terraform"
  }
}

module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"
  key_name_prefix          = "jenkins"
  public_key = file("~/.ssh/id_rsa.pub")
}

module "vpc" {
  source       = "farrukh90/vpc/aws"
  version      = "7.0.0"
  region       = var.vpc_config["region"]
  vpc_cidr     = var.vpc_config["vpc_cidr"]
  public_cidr1 = var.vpc_config["public_cidr1"]
  public_cidr2 = var.vpc_config["public_cidr2"]
  public_cidr3 = var.vpc_config["public_cidr3"]
  tags         = var.tags
}



output "vpc" {
  value = module.vpc.vpc
}
output "public_subnet1" {
  value = module.vpc.public_subnets[0]
}
output "public_subnet2" {
  value = module.vpc.public_subnets[1]
}
output "public_subnet3" {
  value = module.vpc.public_subnets[2]
}
output "region" {
  value = module.vpc.region
}

module "jenkins-sec-group" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "jenkins-sec-group"
  description = "Security group for jenkins-sec-group with custom ports open within VPC, and PostgreSQL publicly open"
  vpc_id      = module.vpc.vpc
  ingress_with_cidr_blocks = [
    {
      rule        = "all-all"
      cidr_blocks = "0.0.0.0/0"
      description = "jenkins-sec-group ports"
    },
  ]
  egress_with_cidr_blocks = [
    {
      rule        = "all-all"
      cidr_blocks = "0.0.0.0/0"
      description = "jenkins-sec-group ports"
    },
  ]
}


####################################################################################################################
module "jenkins" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 4.0"

  # Autoscaling group
  name = "jenkins"

  min_size                  = var.vpc_config["jenkins_min_size"]
  max_size                  = var.vpc_config["jenkins_max_size"]
  desired_capacity          = var.vpc_config["jenkins_desired_capacity"]
  wait_for_capacity_timeout = 0
  health_check_type         = "EC2"
  vpc_zone_identifier       = [module.vpc.public_subnets[0], module.vpc.public_subnets[0]]
  # Launch template
  lt_name                = "jenkins-asg"
  description            = "Launch template for jenkins"
  update_default_version = true

  use_lt    = true
  create_lt = true

  image_id          = var.vpc_config["image_id"]
  instance_type     = var.vpc_config["jenkins_instance_type"]
  key_name          = module.key_pair.key_pair_key_name
  ebs_optimized     = false
  enable_monitoring = false
  security_groups   = [module.jenkins-sec-group.security_group_id]

  block_device_mappings = [
    {
      # Root volume
      device_name = "/dev/xvda"
      no_device   = 0
      ebs = {
        delete_on_termination = true
        volume_size           = 20
        volume_type           = "gp2"
      }
      }, 
  ]

  capacity_reservation_specification = {
    capacity_reservation_preference = "open"
  }

  credit_specification = {
    cpu_credits = "standard"
  }

  tags_as_map = var.tags
}


####################################################################################################################
module "DEV" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 4.0"

  # Autoscaling group
  name = "DEV"

  min_size                  = var.vpc_config["jenkins_min_size"]
  max_size                  = var.vpc_config["jenkins_max_size"]
  desired_capacity          = var.vpc_config["jenkins_desired_capacity"]
  wait_for_capacity_timeout = 0
  health_check_type         = "EC2"
  vpc_zone_identifier       = [module.vpc.public_subnets[0], module.vpc.public_subnets[0]]

  # Launch template
  lt_name                = "DEV-asg"
  description            = "Launch template for DEV"
  update_default_version = true

  use_lt    = true
  create_lt = true

  image_id          = var.vpc_config["image_id"]
  instance_type     = "t3.micro"
  key_name          = module.key_pair.key_pair_key_name

  ebs_optimized     = false
  enable_monitoring = false
  security_groups   = [module.jenkins-sec-group.security_group_id]

  block_device_mappings = [
    {
      # Root volume
      device_name = "/dev/xvda"
      no_device   = 0
      ebs = {
        delete_on_termination = true
        volume_size           = 20
        volume_type           = "gp2"
      }
      }, 
  ]

  capacity_reservation_specification = {
    capacity_reservation_preference = "open"
  }


  credit_specification = {
    cpu_credits = "standard"
  }

  tags_as_map = {
    Name = "DEV"
  }
}


####################################################################################################################
module "QA" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 4.0"

  # Autoscaling group
  name = "QA"

  min_size                  = var.vpc_config["jenkins_min_size"]
  max_size                  = var.vpc_config["jenkins_max_size"]
  desired_capacity          = var.vpc_config["jenkins_desired_capacity"]
  wait_for_capacity_timeout = 0
  health_check_type         = "EC2"
  vpc_zone_identifier       = [module.vpc.public_subnets[0], module.vpc.public_subnets[0]]

  # Launch template
  lt_name                = "QA-asg"
  description            = "Launch template for QA"
  update_default_version = true

  use_lt    = true
  create_lt = true

  image_id          = var.vpc_config["image_id"]
  instance_type     = "t3.micro"
  key_name          = module.key_pair.key_pair_key_name

  ebs_optimized     = false
  enable_monitoring = false
  security_groups   = [module.jenkins-sec-group.security_group_id]

  block_device_mappings = [
    {
      # Root volume
      device_name = "/dev/xvda"
      no_device   = 0
      ebs = {
        delete_on_termination = true
        volume_size           = 20
        volume_type           = "gp2"
      }
      }, 
  ]

  capacity_reservation_specification = {
    capacity_reservation_preference = "open"
  }


  credit_specification = {
    cpu_credits = "standard"
  }

  tags_as_map = {
    Name = "QA"
  }
}


####################################################################################################################
module "STAGE" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 4.0"

  # Autoscaling group
  name = "STAGE"

  min_size                  = var.vpc_config["jenkins_min_size"]
  max_size                  = var.vpc_config["jenkins_max_size"]
  desired_capacity          = var.vpc_config["jenkins_desired_capacity"]
  wait_for_capacity_timeout = 0
  health_check_type         = "EC2"
  vpc_zone_identifier       = [module.vpc.public_subnets[0], module.vpc.public_subnets[0]]

  # Launch template
  lt_name                = "STAGE-asg"
  description            = "Launch template for STAGE"
  update_default_version = true

  use_lt    = true
  create_lt = true

  image_id          = var.vpc_config["image_id"]
  instance_type     = "t3.micro"
  key_name          = module.key_pair.key_pair_key_name

  ebs_optimized     = false
  enable_monitoring = false
  security_groups   = [module.jenkins-sec-group.security_group_id]

  block_device_mappings = [
    {
      # Root volume
      device_name = "/dev/xvda"
      no_device   = 0
      ebs = {
        delete_on_termination = true
        volume_size           = 20
        volume_type           = "gp2"
      }
      }, 
  ]

  capacity_reservation_specification = {
    capacity_reservation_preference = "open"
  }


  credit_specification = {
    cpu_credits = "standard"
  }

  tags_as_map = {
    Name = "STAGE"
  }
}


####################################################################################################################
module "PROD" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 4.0"

  # Autoscaling group
  name = "PROD"

  min_size                  = var.vpc_config["jenkins_min_size"]
  max_size                  = var.vpc_config["jenkins_max_size"]
  desired_capacity          = var.vpc_config["jenkins_desired_capacity"]
  wait_for_capacity_timeout = 0
  health_check_type         = "EC2"
  vpc_zone_identifier       = [module.vpc.public_subnets[0], module.vpc.public_subnets[0]]

  # Launch template
  lt_name                = "PROD-asg"
  description            = "Launch template for PROD"
  update_default_version = true

  use_lt    = true
  create_lt = true

  image_id          = var.vpc_config["image_id"]
  instance_type     = "t3.micro"
  key_name          = module.key_pair.key_pair_key_name

  ebs_optimized     = false
  enable_monitoring = false
  security_groups   = [module.jenkins-sec-group.security_group_id]

  block_device_mappings = [
    {
      # Root volume
      device_name = "/dev/xvda"
      no_device   = 0
      ebs = {
        delete_on_termination = true
        volume_size           = 20
        volume_type           = "gp2"
      }
      }, 
  ]

  capacity_reservation_specification = {
    capacity_reservation_preference = "open"
  }


  credit_specification = {
    cpu_credits = "standard"
  }

  tags_as_map = {
    Name = "PROD"
  }
}

output "Credentials" {
    value = <<EOF


        username: admin
        Passwd: 4a38b31657ff49229462f57b41245e67

        Attach: IAM Admin Role
        Region: "${var.vpc_config["region"]}"
        Port: http://JENKINS_MACHINE_IP_FROM_CONSOLE:8080  (Dont forget port 8080)


    EOF
}