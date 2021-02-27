variable "vpc_id" {}

variable "public_subnets" {
  type = list
}

variable "alb_name" {}
variable "accelerator_name" {}
variable "alb_certificate_arn" {}
variable "alb_dns_name" {}
variable "alb_ssl_policy" {}
