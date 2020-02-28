resource "aws_security_group" "security-group" {
  vpc_id = "${aws_vpc.demo-vpc.id}"
  tags = {
    Name = "nginxalb-sg"
  }

}

resource "aws_security_group_rule" "security-group-rule-ssh" {
    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    security_group_id = "${aws_security_group.security-group.id}"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "security-group-rule-http" {
    type = "ingress"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_group_id = "${aws_security_group.security-group.id}"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "app_server_egress" {
    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = "${aws_security_group.security-group.id}"
}



data "template_cloudinit_config" "master" {
  gzip          = false
  base64_encode = false

part {
    content_type = "text/x-shellscript"
    content      = <<EOF
     #!/bin/bash
     sudo yum update -y
     sudo amazon-linux-extras install nginx1 -y
     sudo systemctl start nginx.service
     sudo systemctl enable nginx.service
 EOF
 }

part {
    content_type = "text/x-shellscript"
    content      = <<EOF
#!/bin/bash
cat <<EOF > /opt/hostname.html
 <html>
 <body>
 <p>Hello World: $(hostname)</p>
 </body>
</html>
EOF
}

part {
    content_type = "text/x-shellscript"
    content      = <<EOF
#!/bin/bash
aws configure set default.region us-east-1;
aws configure set aws_access_key_id 'AKIAXYTRCWUMNGHRUAX5' ;
aws configure set aws_secret_access_key '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' ;
EOF
}


part {
    content_type = "text/x-shellscript"
    content      = <<EOF
#!/bin/bash
sleep 1m
aws s3 cp /opt/hostname.html s3://testprojectnginx/index.html
aws s3api put-object-acl --bucket testprojectnginx --key index.html --acl public-read
EOF
}

part {
    content_type = "text/x-shellscript"
    content      = <<EOF
#!/bin/bash
sudo sed -i "48iproxy_set_header Host 'testprojectnginx.s3.amazonaws.com';" /etc/nginx/nginx.conf
sudo sed -i "49iproxy_set_header Authorization '';" /etc/nginx/nginx.conf
sudo sed -i '50iproxy_hide_header x-amz-id-2;' /etc/nginx/nginx.conf
sudo sed -i '51iproxy_hide_header x-amz-request-id;' /etc/nginx/nginx.conf
sudo sed -i '52iproxy_hide_header Set-Cookie;' /etc/nginx/nginx.conf
sudo sed -i '53iproxy_ignore_headers "Set-Cookie";' /etc/nginx/nginx.conf
sudo sed -i '54iproxy_intercept_errors on;' /etc/nginx/nginx.conf
sudo sed -i '55iproxy_pass https://testprojectnginx.s3.amazonaws.com/index.html;' /etc/nginx/nginx.conf
sudo sed -i '56iexpires 1y;' /etc/nginx/nginx.conf
sudo sed -i '57ilog_not_found off;' /etc/nginx/nginx.conf
sudo sed -i '42d' /etc/nginx/nginx.conf
sudo systemctl restart nginx.service
EOF
}
}

resource "aws_launch_configuration" "terraform-lc" {
  name_prefix = "nginx-LaunchConfiguration"
  image_id           = "ami-00dc79254d0461090"
  instance_type = "t2.micro"
  key_name = "Project"
  user_data     = "${data.template_cloudinit_config.master.rendered}"
  security_groups = ["${aws_security_group.security-group.id}"]
  associate_public_ip_address = "true"

lifecycle {
    create_before_destroy = true
  }
}

data "aws_instances" "test" {

filter {
name   = "tag:Name"
values = ["nginx-server"]
}

depends_on = [
  "aws_autoscaling_group.terraform-asg"
  ]
}


resource "aws_autoscaling_group" "terraform-asg" {

  name = "nginx-asg"
  min_size             = "1"
  desired_capacity     = "1"
  max_size             = "1"
  health_check_type    ="EC2"
  launch_configuration = "${aws_launch_configuration.terraform-lc.name}"
  vpc_zone_identifier  = ["${aws_subnet.demo-subnet-public.id}"]

  tag {
    key                 = "Name"
    value               = "nginx-server"
    propagate_at_launch = true
  }

}


