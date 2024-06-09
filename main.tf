provider "aws" {
  region  = "us-east-1"
  profile = "first"
}

# S3 Bucket for Static Website
resource "aws_s3_bucket" "photo_album" {
  bucket = "lavialdo-first-bucket"
}

# S3 Bucket Website Configuration
resource "aws_s3_bucket_website_configuration" "photo_album_website" {
  bucket = aws_s3_bucket.photo_album.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Bucket Policy to Allow Access Only from Specific IP
resource "aws_s3_bucket_policy" "photo_album_policy" {
  bucket = aws_s3_bucket.photo_album.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = "*",
        Action = "s3:GetObject",
        Resource = "${aws_s3_bucket.photo_album.arn}/*",
        Condition = {
          IpAddress = {
            "aws:SourceIp" = "109.186.11.187/32"
          }
        }
      }
    ]
  })
}

# Security Group for RDS
resource "aws_security_group" "rds_access" {
  name        = "rds_access"
  description = "Allow access to RDS"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["34.224.216.238/32"]  # Your IP address
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# RDS Instance for metadata storage
resource "aws_db_instance" "photo_metadata" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0.35"
  instance_class       = "db.t3.micro"
  db_name              = "photoalbumdb"
  username             = "admin"
  password             = "324273846"
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  publicly_accessible  = true

  vpc_security_group_ids = [aws_security_group.rds_access.id]

  tags = {
    Name = "PhotoAlbumRDS"
  }
}
