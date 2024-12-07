#DynamoDB Table
resource "aws_dynamodb_table" "dynamodb" {
  name         = var.tablename
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "ISBN"
  range_key    = "Genre"

  attribute {
    name = "ISBN"
    type = "S"
  }

  attribute {
    name = "Genre"
    type = "S"
  }

  provisioner "local-exec" {
    command = "./items.sh ${var.tablename} ${var.region}"

  }

  tags = {
    Name = var.tablename
  }
}

#EC2 Instance
resource "aws_instance" "public" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t2.micro"
  subnet_id                   = data.aws_subnets.public.ids[0]
  associate_public_ip_address = true
  security_groups             = [aws_security_group.my_security_group.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  key_name                    = var.keypair

  user_data = <<-EOF
            #!/bin/bash
            echo "export AWS_DEFAULT_REGION=${var.region}" >> /etc/profile
            mkdir -p /home/ec2-user/.aws
            echo "[default]" > /home/ec2-user/.aws/config
            echo "region = ${var.region}" >> /home/ec2-user/.aws/config
            chown -R ec2-user:ec2-user /home/ec2-user/.aws
            EOF

  tags = {
    Name = var.ec2name
  }
}

#EC2 Security Group
resource "aws_security_group" "my_security_group" {
  name_prefix = "${var.name}-dynamodb-sg"
  description = "Allow SSH and HTTPS inbound"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

#IAM Policy
resource "aws_iam_policy" "policy" {
  name = "${var.name}-dynamodb-read"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "VisualEditor0",
        Effect = "Allow",
        Action = [
          "dynamodb:BatchGetItem",
          "dynamodb:DescribeImport",
          "dynamodb:ConditionCheckItem",
          "dynamodb:DescribeContributorInsights",
          "dynamodb:Scan",
          "dynamodb:ListTagsOfResource",
          "dynamodb:Query",
          "dynamodb:DescribeStream",
          "dynamodb:DescribeTimeToLive",
          "dynamodb:DescribeGlobalTableSettings",
          "dynamodb:PartiQLSelect",
          "dynamodb:DescribeTable",
          "dynamodb:GetShardIterator",
          "dynamodb:DescribeGlobalTable",
          "dynamodb:GetItem",
          "dynamodb:DescribeContinuousBackups",
          "dynamodb:DescribeExport",
          "dynamodb:GetResourcePolicy",
          "dynamodb:DescribeKinesisStreamingDestination",
          "dynamodb:DescribeBackup",
          "dynamodb:GetRecords",
          "dynamodb:DescribeTableReplicaAutoScaling"
        ],
        Resource = aws_dynamodb_table.dynamodb.arn
      },
      {
        Sid    = "VisualEditor1",
        Effect = "Allow",
        Action = [
          "dynamodb:ListContributorInsights",
          "dynamodb:DescribeReservedCapacityOfferings",
          "dynamodb:ListGlobalTables",
          "dynamodb:ListTables",
          "dynamodb:DescribeReservedCapacity",
          "dynamodb:ListBackups",
          "dynamodb:GetAbacStatus",
          "dynamodb:ListImports",
          "dynamodb:DescribeLimits",
          "dynamodb:DescribeEndpoints",
          "dynamodb:ListExports",
          "dynamodb:ListStreams"
        ],
        Resource = "*"
      }
    ]
  })
}

#IAM Role
resource "aws_iam_role" "ec2_dynamodb_role" {
  name = "${var.name}-ec2-dynamodb-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.name}-ec2-dynamodb-role"
  }
}

#Role Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.name}-ec2-profile"
  role = aws_iam_role.ec2_dynamodb_role.name
}

#Role Attachment
resource "aws_iam_role_policy_attachment" "dynamodb_policy_attachment" {
  role       = aws_iam_role.ec2_dynamodb_role.name
  policy_arn = aws_iam_policy.policy.arn
}
