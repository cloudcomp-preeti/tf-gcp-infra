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

variable "googlecred" {
  type = string
}

variable "ip_name" {
  type = string
}

variable "ip_purpose" {
  type = string
}

variable "ip_type" {
  type = string
}

variable "service_name" {
  type = string
}

variable "db_instance_name" {
  type = string
}

variable "database_version" {
  type = string
}

variable "db_tier" {
  type = string
}

variable "db_disk_type" {
  type = string
}

variable "db_size" {
  type = number
}

variable "db_availablity_type" {
  type = string
}

variable "sql_db_name" {
  type = string
}

variable "override_special" {
  type = string
}

variable "sql_user_name" {
  type = string
}

variable "postgres_port" {
  type = string
}

variable "postgres_dialect" {
  type = string
}