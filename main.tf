provider "aws" {
  region = "us-west-1"
}

data "aws_region" "current" {}

resource "aws_vpc" "sb_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "sbVPC"
  }
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "wp_subnet_1" {
  vpc_id                  = aws_vpc.sb_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = element(data.aws_availability_zones.available.names, 0)

  tags = {
    Name = "wpSubnet1"
  }
}


resource "aws_subnet" "wp_subnet_2" {
  vpc_id                  = aws_vpc.sb_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = element(data.aws_availability_zones.available.names, 1)

  tags = {
    Name = "wpSubnet2"
  }
}

resource "aws_internet_gateway" "wp_internet_gateway" {
  vpc_id = aws_vpc.sb_vpc.id
}


resource "aws_route_table" "wp_route_table" {
  vpc_id = aws_vpc.sb_vpc.id
}


resource "aws_route" "wp_route" {
  route_table_id         = aws_route_table.wp_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.wp_internet_gateway.id
}

resource "aws_route_table_association" "private_subnet_assoc_1" {
  count          = length(data.aws_availability_zones.available.names)
  subnet_id      = element(aws_subnet.wp_subnet_1.*.id, count.index)
  route_table_id = aws_route_table.wp_route_table.id
}

resource "aws_route_table_association" "private_subnet_assoc_2" {
  count          = length(data.aws_availability_zones.available.names)
  subnet_id      = element(aws_subnet.wp_subnet_2.*.id, count.index)
  route_table_id = aws_route_table.wp_route_table.id
}

resource "aws_security_group" "eks_security_group" {
  name        = "EKSSecurityGroup"
  description = "EKS security group"
  vpc_id      = aws_vpc.sb_vpc.id

  ingress = [
    {
      description      = "In TCP 80"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      description      = "In TCP 443"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      description      = "Allow all inbound traffic from within the security group"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      self             = true
      security_groups  = []
      cidr_blocks      = []
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
    },
  ]

  egress = [
    {
      description      = "Allow all outbound traffic to the Internet"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
  ]
}


#resource "aws_elb" "application_loadbalancer" {
#  name            = "ApplicationLoadBalancer"
#  subnets         = [aws_subnet.wp_subnet_1.id, aws_subnet.wp_subnet_2.id]
#  security_groups = [aws_security_group.eks_security_group.id]
#
#  listener {
#    instance_port     = 80
#    instance_protocol = "http"
#    lb_port           = 80
#    lb_protocol       = "http"
#  }
#
#  listener {
#    instance_port     = 443
#    instance_protocol = "http"
#    lb_port           = 443
#    lb_protocol       = "http"
#  }
#
#  health_check {
#    interval            = 10
#    timeout             = 5
#    healthy_threshold   = 2
#    unhealthy_threshold = 5
#    target              = "HTTP:80/wp-admin/install.php"
#  }
#
#}

#resource "aws_network_interface" "sb_eni" {
#  subnet_id       = aws_subnet.wp_subnet_1.id
#  security_groups = [aws_security_group.eks_security_group.id]
#}

# Allocate an Elastic IP address
resource "aws_eip" "sb_dev" {
  #  network_interface         = aws_network_interface.sb_eni.id
}

# Create a Network Load Balancer
#resource "aws_lb" "eks_nlb" {
#  name               = "EKSNetworkLoadBalancer"
#  internal           = false
#  load_balancer_type = "network"
#  subnets            = [aws_subnet.wp_subnet_1.id, aws_subnet.wp_subnet_2.id]
#
#  access_logs {
#    bucket  = aws_s3_bucket.lb_logs.id
#    #    prefix  = "eks-nlb"
#    enabled = true
#  }
#}
#
#data "aws_elb_service_account" "main" {}
#
#resource "aws_s3_bucket" "lb_logs" {
#  bucket = "sb-eks-lb-logs"
#}
#
#resource "aws_s3_bucket_policy" "allow_access_lb" {
#  bucket = aws_s3_bucket.lb_logs.id
#  policy = data.aws_iam_policy_document.allow_access_lb.json
#}
#
#
#data "aws_iam_policy_document" "allow_access_lb" {
#  version = "2012-10-17"
#
#  statement {
#    sid    = "AWSLogDeliveryAclCheck"
#    effect = "Allow"
#
#    actions = [
#      "s3:GetBucketAcl"
#    ]
#
#    resources = [
#      aws_s3_bucket.lb_logs.arn
#    ]
#
##    condition {
##      test     = "StringEquals"
##      variable = "aws:SourceAccount"
##      values   = ["${var.source_account_id}"]
##    }
##
##    condition {
##      test     = "ArnLike"
##      variable = "aws:SourceArn"
##      values   = ["arn:aws:logs:${data.aws_region.current.id}:${var.source_account_id}:*"]
##    }
#
#    principals {
#      type        = "Service"
#      identifiers = ["delivery.logs.amazonaws.com"]
#    }
#  }
#
#  statement {
#    sid    = "AWSLogDeliveryWrite"
#    effect = "Allow"
#
#    actions = [
#      "s3:PutObject"
#    ]
#
#    resources = [
#      "${aws_s3_bucket.lb_logs.arn}/AWSLogs/${var.source_account_id}/*"
#    ]
#
#    condition {
#      test     = "StringEquals"
#      variable = "s3:x-amz-acl"
#      values   = ["bucket-owner-full-control"]
#    }
#
##    condition {
##      test     = "StringEquals"
##      variable = "aws:SourceAccount"
##      values   = ["${var.source_account_id}"]
##    }
##
##    condition {
##      test     = "ArnLike"
##      variable = "aws:SourceArn"
##      values   = ["arn:aws:logs:${data.aws_region.current.id}:${var.source_account_id}:*"]
##    }
#
#    principals {
#      type        = "Service"
#      identifiers = ["delivery.logs.amazonaws.com"]
#    }
#  }
#}

#resource "aws_iam_role" "nlb_log_role" {
#  name = "NLBlogRole"
#
#  assume_role_policy = jsonencode({
#    Version = "2012-10-17",
#    Statement = [
#      {
#        Action = "sts:AssumeRole",
#        Effect = "Allow",
#        Principal = {
#          Service = "logdelivery.elasticloadbalancing.amazonaws.com"
#        }
#      }
#    ]
#  })
#}
#
#resource "aws_iam_policy" "nlb_s3_policy" {
#  name = "NLBs3Policy"
#
#  policy = jsonencode({
#    Version = "2012-10-17",
#    Statement = [
#      {
#        Action = [
#          "s3:PutObject"
#        ],
#        Effect = "Allow",
#        Resource = "${aws_s3_bucket.lb_logs.arn}/*",
#      }
#    ]
#  })
#}
#
#resource "aws_iam_role_policy_attachment" "nlb_policy_attachment" {
#  policy_arn = aws_iam_policy.nlb_s3_policy.arn
#  role       = aws_iam_role.nlb_log_role.name
#}

#resource "aws_lb_target_group" "eks_http_target_group" {
#  name     = "EKShttpTargetGroup"
#  port     = 80
#  protocol = "TCP"
#  vpc_id   = aws_vpc.sb_vpc.id
#}
#
#resource "aws_lb_target_group" "eks_https_target_group" {
#  name     = "EKShttpsTargetGroup"
#  port     = 443
#  protocol = "TCP"
#  vpc_id   = aws_vpc.sb_vpc.id
#}
#
## Configure NLB Listeners and Target Groups for Port 80
#resource "aws_lb_listener" "eks_http_listener" {
#  load_balancer_arn = aws_lb.eks_nlb.arn
#  port              = 80
#  protocol          = "TCP"
#
#  default_action {
#    type             = "forward"
#    target_group_arn = aws_lb_target_group.eks_http_target_group.arn
#  }
#}
#
## Configure NLB Listeners and Target Groups for Port 443
#resource "aws_lb_listener" "eks_https_listener" {
#  load_balancer_arn = aws_lb.eks_nlb.arn
#  port              = 443
#  protocol          = "TCP"
#
#  default_action {
#    type             = "forward"
#    target_group_arn = aws_lb_target_group.eks_https_target_group.arn
#  }
#}


#
#resource "aws_autoscaling_group" "worker-nodes" {
#  name = "worker-nodes"
#  desired_capacity   = 1
#  max_size           = 6
#  min_size           = 1
#  vpc_zone_identifier  = [aws_subnet.WPSubnet1.id, aws_subnet.WPSubnet2.id]
#
#  launch_template {
#    id      = aws_launch_template.worker-nodes.id
#    version = "$Latest"
#  }
#}

