##---Create VPC---##

resource "aws_vpc" "demo-vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support = "true" 
    enable_dns_hostnames = "true" 
    enable_classiclink = "false"
    instance_tenancy = "default"    
    
    tags = {
        Name = "demo-vpc"
    }
}

##---Create Public Subnet---##

resource "aws_subnet" "demo-subnet-public" {
    vpc_id = "${aws_vpc.demo-vpc.id}"
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = "true"
    availability_zone = "us-east-1a"
tags = {
Name = "demo-subnet-public"
}
}

resource "aws_subnet" "demo-subnet-public-1" {
    vpc_id = "${aws_vpc.demo-vpc.id}"
    cidr_block = "10.0.2.0/24"
    map_public_ip_on_launch = "true"
    availability_zone = "us-east-1b"
tags = {
Name = "demo-subnet-public-1"
}
}

##---Create Internet Gateway---##

resource "aws_internet_gateway" "demo-igw" {
    vpc_id = "${aws_vpc.demo-vpc.id}"
    tags = {
        Name = "demo-igw"
    }
}

##---Create Custom Route Table---##

resource "aws_route_table" "demo-public-crt" {
    vpc_id = "${aws_vpc.demo-vpc.id}"
    
    route {
        //associated subnet can reach everywhere
        cidr_block = "0.0.0.0/0" 
        //CRT uses this IGW to reach internet
        gateway_id = "${aws_internet_gateway.demo-igw.id}" 
    }
    
    tags = {
        Name = "demo-public-crt"
    }
}

##---Associate CRT and subnet---##

resource "aws_route_table_association" "demo-crta-public-subnet-1"{
    subnet_id = "${aws_subnet.demo-subnet-public.id}"
    route_table_id = "${aws_route_table.demo-public-crt.id}"
}

##---Create Security Group---##

resource "aws_security_group" "ssh-allowed" {
    vpc_id = "${aws_vpc.demo-vpc.id}"
    
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "ssh-allowed"
    }
}

