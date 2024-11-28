# Creating the IP Set tp be defined in AWS WAF 
resource "aws_waf_ipset" "ipset" {
  name = "MyFirstipset"
  ip_set_descriptors {
    type  = "IPV4"
    value = "10.111.0.0/20"
  }
}

# Creating the AWS WAF rule that will be applied on AWS Web ACL
resource "aws_waf_rule" "waf_rule" {
  depends_on  = [aws_waf_ipset.ipset]
  name        = var.waf_rule_name
  metric_name = var.waf_rule_metrics
  predicates {
    data_id = aws_waf_ipset.ipset.id
    negated = false
    type    = "IPMatch"
  }
}

# Creating the Rule Group which will be applied on  AWS Web ACL

resource "aws_waf_rule_group" "rule_group" {
  name        = var.waf_rule_group_name
  metric_name = var.waf_rule_metrics

  activated_rule {
    action {
      type = "COUNT"
    }
    priority = 50
    rule_id  = aws_waf_rule.waf_rule.id
  }
}

# Creating the Web ACL component in AWS WAF

resource "aws_waf_web_acl" "waf_acl" {
  depends_on = [
    aws_waf_rule.waf_rule,
    aws_waf_ipset.ipset,
  ]
  name        = var.web_acl_name
  metric_name = var.web_acl_metics

  default_action {
    type = "ALLOW"
  }
  rules {
    action {
      type = "BLOCK"
    }
    priority = 1
    rule_id  = aws_waf_rule.waf_rule.id
    type     = "REGULAR"
  }
}

resource "aws_security_group" "app_sg" {
  name_prefix = "app-sg-"
  vpc_id      = aws_vpc.app_vpc.id # ID de votre VPC existant

  # Autoriser le trafic entrant depuis une source publique (par exemple, pour HTTP)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Autoriser le trafic sortant vers une destination publique (par exemple, pour HTTP)
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Autoriser SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Autoriser l'application à accéder à une des bases de données
  # ingress {
  #   from_port   = 3306 # Par exemple, pour MySQL
  #   to_port     = 3306
  #   protocol    = "tcp"
  #   security_groups = ["<DB-SG-ID>"] # ID du SG de la base de données autorisée
  # }

  # Blocage de tout autre trafic sortant
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# resource "aws_wafv2_web_acl_association" "waf_acl_association" {
#   resource_arn = aws_instance.app_ec2.arn
#   web_acl_arn  = aws_waf_web_acl.waf_acl.arn
# }


# Réseau VPC
resource "aws_vpc" "app_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "pb_subnet_AZ1" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = var.pb1_subnet_cidr
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "pb_subnet_AZ2" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = var.pb2_subnet_cidr
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "pv1_subnet_AZ1" {
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = var.pv1_subnet_cidr
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "pv2_subnet_AZ1" {
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = var.pv2_subnet_cidr
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "pv1_subnet_AZ2" {
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = var.pv3_subnet_cidr
  availability_zone = "us-east-1b"
}

resource "aws_subnet" "pv2_subnet_AZ2" {
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = var.pv4_subnet_cidr
  availability_zone = "us-east-1b"
}

resource "aws_internet_gateway" "app_igw" {
  vpc_id = aws_vpc.app_vpc.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.app_vpc.id
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.app_igw.id
}

resource "aws_route_table_association" "public_rt_assoc_AZ1" {
  subnet_id      = aws_subnet.pb_subnet_AZ1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rt_assoc_AZ2" {
  subnet_id      = aws_subnet.pb_subnet_AZ2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt_AZ1" {
  vpc_id = aws_vpc.app_vpc.id
}

resource "aws_route_table" "private_rt_AZ2" {
  vpc_id = aws_vpc.app_vpc.id
}

resource "aws_route_table_association" "private_rt_assoc_pv1_AZ1" {
  subnet_id      = aws_subnet.pv1_subnet_AZ1.id
  route_table_id = aws_route_table.private_rt_AZ1.id
}

resource "aws_route_table_association" "private_rt_assoc_pv2_AZ1" {
  subnet_id      = aws_subnet.pv2_subnet_AZ1.id
  route_table_id = aws_route_table.private_rt_AZ1.id
}

resource "aws_route_table_association" "private_rt_assoc_pv1_AZ2" {
  subnet_id      = aws_subnet.pv1_subnet_AZ2.id
  route_table_id = aws_route_table.private_rt_AZ2.id
}

resource "aws_route_table_association" "private_rt_assoc_pv2_AZ2" {
  subnet_id      = aws_subnet.pv2_subnet_AZ2.id
  route_table_id = aws_route_table.private_rt_AZ2.id
}

# Création de l'instance EC2 de l'application dans AZ1
resource "aws_instance" "app_ec2_AZ1" {
  ami             = "ami-0866a3c8686eaeeba" # AMI Ubuntu ou Amazon Linux
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.pb_subnet_AZ1.id
  security_groups = [aws_security_group.app_sg.id]

  user_data = file("./scripts/setup.sh")

  tags = {
    Name = "App-Instance-AZ1"
  }
}

# Création de l'instance EC2 de l'application dans AZ2
resource "aws_instance" "app_ec2_AZ2" {
  ami             = "ami-0866a3c8686eaeeba" # AMI Ubuntu ou Amazon Linux
  instance_type   = "t3.micro"
  subnet_id       = aws_subnet.pb_subnet_AZ2.id
  security_groups = [aws_security_group.app_sg.id]

  user_data = file("./scripts/setup.sh")



  tags = {
    Name = "App-Instance-AZ2"
  }
}

