variable "project_id" {
  type    = string
}

variable "region" {
  type    = string
}

variable "num_instances" {
  type    = number
}

variable "routing_mode" {
    type = string
}

variable "internet-gateway" {
  type = string
}

variable "subnet-webapp" {
  type = string
}

variable "subnet-db" {
  type = string
}

variable "webapp-route" {
  type = string
}

variable "vpc-network" {
    type = string
}

variable "webapp-cidr" {
    type = string
}

variable "db-cidr" {
    type = string
}

variable "route-config" {
    type = string
}

variable "application_port" {
  type = string
}

variable "webapp-firewall" {
  type = string
}


// Instance Variables
variable "instance_image" {
  type = string
}

variable "instance_machine_type" {
  type = string
}

variable "instance_name" {
  type = string
}