/* Ireland region */
variable "aws_region" {  default = "eu-west-1" }

variable "state_bucket_name"    { default = "remote-states" }
variable "vpc_remote-state_key" { default = "steam/vpc.state" }

/* environment definition */
variable "NetworkName" {}
variable "Environment" {}
variable "module" {}

/* Network variables */ 

variable "az_a" { default = "eu-west-1a" }
variable "az_b" { default = "eu-west-1b" }
variable "az_c" { default = "eu-west-1c" }

/* 64k hosts */
variable "vpc_cidr" { default = "172.20.0.0/16" }

variable "subnet_a_cidr" { default = "172.20.0.0/18" }
variable "subnet_b_cidr" { default = "172.20.64.0/18" }
variable "subnet_c_cidr" { default = "172.20.128.0/18" }
