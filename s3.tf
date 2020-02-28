resource "aws_s3_bucket" "test" {
  acl    = "private"
  bucket = "testprojectnginx"

  tags = {
    Name = "testprojectnginx1"
  }
}

