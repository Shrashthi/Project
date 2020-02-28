
// Security Group For Public ALB
resource "aws_security_group" "public-lb-sg" {
  name  = "nginx-sg"

  tags = {
    Name = "nginx-sg"  
  }

  vpc_id = "${aws_vpc.demo-vpc.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// Public ALB

resource "aws_lb" "public-lb" {
  name               = "nginx"
  internal           = false
  load_balancer_type = "application"
  subnets            = ["${aws_subnet.demo-subnet-public.id}","${aws_subnet.demo-subnet-public-1.id}"]
  security_groups    = ["${aws_security_group.public-lb-sg.id}"]
  idle_timeout       = 600

  tags = {
    Name = "nginx-test"
  }
}


// ALB Listener HTTP
resource "aws_alb_listener" "alb-listener-http" {
  load_balancer_arn = "${aws_lb.public-lb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.alb-target-group.id}"
  }
}


// ALB Target Group
resource "aws_alb_target_group" "alb-target-group" {
  name  = "nginx-tg"

  tags = {
    name = "nginx-tg"
  }

  port     = "80"
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.demo-vpc.id}"

  health_check {
    timeout             = 5
    interval            = 30
    unhealthy_threshold = 10
    healthy_threshold   = 2
    path                = "/"
    port                = "80"
  }
}

// ALB Target Group Attachment
//resource "aws_lb_target_group_attachment" "target_group_attachment" {
//  target_group_arn = "${aws_alb_target_group.alb-target-group.arn}"
//  target_id        = "${var.instance_id}"
//  port             = 80
//}

resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = "${aws_autoscaling_group.terraform-asg.name}"
  alb_target_group_arn   = "${aws_alb_target_group.alb-target-group.arn}"
}


