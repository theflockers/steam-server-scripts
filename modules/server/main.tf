/* aws provider */
provider "aws" {
  region = "${var.aws_region}"
}

/* instances */
variable "count" { default = 1 }

/* get network remote state before continue */
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    region = "${var.aws_region}"
    bucket = "${var.state_bucket_name}"
    key    = "${var.vpc_remote-state_key}"
  }
}

/* my ansible default keypair for provisioning */
resource "aws_key_pair" "ansible" {
    key_name   = "ansible"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDLIqPHtXdI0TIER8zx+0YYn8loXdwZp7m7NYx6tVmfAhqoewNg80U54NKUIJd507vVhieTUstR8G4jewH0KJ/akGGRJwCceaq6Ybn2X6fGmMNo3uPQESVkVWvv4s4mNmiMSKwhe9w6N5eGt895KNzXbu3TqAdjZ/3E5Tg20OY1gNwkw2CcOveDl4iyP7C2Vw/8s/gX+sug8s3tUQNulWOU1k9LIE3yqQzxR9R3y6xiCQL2OaG9BRfVm66lSevhUmSQYMidNnU5TqUptVUcZADBTI0u62KJn7eJEfHnP93dUd8jJJP9BbySDT9e49DTRiuZF2y5O55gouNycNWs01Cz"
}

/* shared filesystem for games */
resource "aws_efs_file_system" "game-files" {
  tags {
    Name = "game-files"
  }
}

/* allow endpoint to be reached by all subnets */
resource "aws_efs_mount_target" "games-efs-target" {
  count          = 3
  file_system_id = "${aws_efs_file_system.game-files.id}"
  subnet_id      = "${element(list(data.terraform_remote_state.vpc.subnet_a_id,data.terraform_remote_state.vpc.subnet_b_id,data.terraform_remote_state.vpc.subnet_c_id), count.index)}"
  depends_on     = [ "aws_efs_file_system.game-files" ]
} 


/* SECURITY GROUPS */

/* default SG */
resource "aws_default_security_group" "default" {
  vpc_id      = "${data.terraform_remote_state.vpc.vpc_id}"

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

/* allow access to ssh port from home */
resource "aws_security_group" "home_network_allow_ssh" {
  name   = "home_network_allow_ssh"
  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"
  ingress {
      from_port   = 0
      to_port     = 22 
      protocol    = "tcp"
      cidr_blocks = ["95.91.246.104/32"]
  }
}

/* allow public traffic to steam server */
resource "aws_security_group" "public_network_allow_steam_traffic" {
  name   = "public_network_allow_steam_traffic"
  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"

  /* game port */
  ingress {
      from_port   = 27000
      to_port     = 27015
      protocol    = "udp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  /* HLTV port */
  ingress {
      from_port   = 27016
      to_port     = 27030
      protocol    = "udp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  /* steam download */
  ingress {
      from_port   = 27014
      to_port     = 27050
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  /* steam client */
  ingress {
      from_port   = 0
      to_port     = 4380
      protocol    = "udp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  /* allow all output */
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


/* create steam instances */
resource "aws_instance" "steam-server" {
  count         = "${var.count}"
  ami           = "ami-8fd760f6"
  subnet_id     = "${element(data.terraform_remote_state.vpc.subnets, count.index)}"
  instance_type = "t2.small"
  tags          = {
    Name        = "steam-${count.index}"
    Environment = "${var.Environment}",
  }
  key_name      = "ansible"
  vpc_security_group_ids  = [
    "${aws_default_security_group.default.id}",
    "${aws_security_group.public_network_allow_steam_traffic.id}",
    "${aws_security_group.home_network_allow_ssh.id}"
  ]

  # provisioning - stg yet, not final
  user_data      = "${file("user-data.txt")}"
}

/*
 * as terraform does not allow  interpolation on its  own  resource
 * better this way because you can run without destroy the instance
 */
resource "null_resource" "run-ansible" {
  count      = "${var.count}"
  provisioner "local-exec" {
    command  = "python ../../bin/run-ansible.py -m ${var.module} -i ${element(aws_instance.steam-server.*.public_dns, count.index)} -d ${aws_efs_file_system.game-files.dns_name}:/"
  }
  depends_on = [
      "aws_instance.steam-server"
  ]
}
