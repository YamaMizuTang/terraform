variable "vpc_cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

variable "private_subnet_cidr_block" {
  type    = string
  default = "10.0.0.0/20"
}

variable "public_subnet_cidr_block" {
  type    = string
  default = "10.0.16.0/20"
}

variable "key_name" {
  type    = string
  default = "key"
}