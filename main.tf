provider aws {
 access_key = var.access_key
 secret_key = var.secret_key
 region = var.region
}


data aws_vpc k8s_vpc {
 filter {
  name = "tag:Name"
  values = var.vpc_name
 }
}

data aws_subnet_ids k8s_pub_subnet {
 vpc_id = data.aws_vpc.k8s_vpc.id
 
 filter {
  name = "tag:Name"
  values = var.pub_subnet_name
 }
}


data aws_subnet_ids k8s_prv_subnet {
 vpc_id = data.aws_vpc.k8s_vpc.id
 
 filter {
  name = "tag:Name"
  values = var.prv_subnet_name
 }
}

resource aws_security_group public {
  name = var.nsg_name
  vpc_id = data.aws_vpc.k8s_vpc.id

  ingress {
    cidr_blocks = var.ssh_cidr
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }

  egress {
   cidr_blocks = ["0.0.0.0/0"]
   from_port = 0
   to_port = 0
   protocol = "-1"
 }
} 

resource aws_security_group master {
 vpc_id =  data.aws_vpc.k8s_vpc.id

 ingress {
  security_groups = [aws_security_group.public.id]
  from_port = 22
  to_port = 22
  protocol = "tcp"
 }

 ingress {
  security_groups = [aws_security_group.private.id]
  from_port = 6443
  to_port = 6443
  protocol = "tcp"
 }

 egress {
   cidr_blocks = ["0.0.0.0/0"]
   from_port = 0
   to_port = 0
   protocol = "-1"
 }

 depends_on = [
  aws_security_group.private
 ]
}

resource aws_security_group private {
 vpc_id =  data.aws_vpc.k8s_vpc.id

 ingress {
  security_groups = [aws_security_group.public.id]
  from_port = 22
  to_port = 22
  protocol = "tcp"
 }

 egress {
   cidr_blocks = ["0.0.0.0/0"]
   from_port = 0
   to_port = 0
   protocol = "-1"
 }

 depends_on = [
  aws_security_group.public
 ]
}

data aws_ami public_box {
  most_recent = true

  filter {
    name   = "tag:Name"
    values = ["Jump-server"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["348396111470"]
}

data aws_ami private_box {
  most_recent = true

  filter {
    name   = "tag:Name"
    values = ["k8s-image"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["348396111470"]
}

resource aws_instance pub_box {
 for_each = data.aws_subnet_ids.k8s_pub_subnet.ids
 ami = data.aws_ami.public_box.id
 instance_type = var.pub_instance_type
 subnet_id = each.value
 security_groups = [aws_security_group.public.id]
 key_name = "docker" 


 tags = { 
  Name = var.pub_instance_name
 }
}

resource aws_instance prv_box_main {
 count = var.prv_main_box_count
 ami = data.aws_ami.private_box.id
 instance_type = var.prv_instance_type
 subnet_id = element(tolist(data.aws_subnet_ids.k8s_prv_subnet.ids), count.index) 
 security_groups = [aws_security_group.master.id]
 key_name = "Jump-key"
 
 tags = {
  Name = var.prv_main_instance_name
 }
}

resource aws_instance prv_box {
 count = var.prv_box_count
 ami = data.aws_ami.private_box.id
 instance_type = var.prv_instance_type
 subnet_id = element(tolist(data.aws_subnet_ids.k8s_prv_subnet.ids), count.index)
 security_groups = [aws_security_group.private.id]
 key_name = "Jump-key"

 tags = {
  Name = format("${var.prv_instance_name}-%d", count.index + 1 )
 }
}
