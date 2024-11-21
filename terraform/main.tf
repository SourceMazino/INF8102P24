provider "aws" {
  region = "us-east-1" # Remplacez par votre région
}

resource "aws_security_group" "app_sg" {
  name_prefix = "app-sg-"
  vpc_id      = "vpc-0c3709209e3f6d013" # ID de votre VPC existant

  # Autoriser le trafic entrant depuis une source publique (par exemple, pour HTTP)
  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_instance" "app_ec2" {
  ami           = "ami-0866a3c8686eaeeba" # AMI Ubuntu ou Amazon Linux
  instance_type = "t3.micro"
  subnet_id     = "subnet-03930ad7d513dfd83" # Subnet pour l'isolation
  security_groups = [aws_security_group.app_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y docker
    systemctl start docker
    systemctl enable docker
    docker run -d -p 80:80 webgoat/webgoat:latest
  EOF

  tags = {
    Name = "App-Instance"
  }
}

# WAF ACL pour protéger l'application
resource "aws_wafv2_web_acl" "app_waf" {
  name        = "App-WAF"
  scope       = "REGIONAL" # Pour les ALB/NLB
  description = "WAF pour l application"
  default_action {
    allow {}
  }

  rule {
    name     = "BlockBadRequests"
    priority = 1

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    action {
      block {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BlockedRequests"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "WAFMetrics"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "waf_association" {
  resource_arn = aws_instance.app_ec2.arn
  web_acl_arn  = aws_wafv2_web_acl.app_waf.arn
}

# Surveillance CloudWatch
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/app"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_stream" "app_stream" {
  log_group_name = aws_cloudwatch_log_group.app_logs.name
  name           = "app-stream"
}

# CloudTrail
# resource "aws_cloudtrail" "trail" {
#   name                          = "App-Trail"
#   s3_bucket_name                = "<S3-BUCKET-FOR-LOGS>"
#   is_multi_region_trail         = true
#   enable_log_file_validation    = true
#   cloud_watch_logs_group_arn    = aws_cloudwatch_log_group.app_logs.arn
#   cloud_watch_logs_role_arn     = "<IAM-ROLE-FOR-CLOUDTRAIL>"
#   include_global_service_events = true
# }
