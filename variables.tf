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

variable "allow-firewall" {
  type = string
}

variable "postgres-port" {
  type = string
}

variable "ssh-port" {
  type = string
}

variable "service-acc-id" {
  type = string
}

variable "service-acc-dispname" {
  type = string
}

variable "role-logging" {
  type = string
}

variable "role-monitormetric" {
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

variable "dns-const" {
  type = string
}

variable "dns-managed-zone" {
  type = string
}

variable "pub-service-acc-id" {
  type = string
}

variable "pub-service-acc-dispname" {
  type = string
}

variable "role-publisher" {
  type = string
}

variable "topic-name" {
  type = string
}

variable "message-retention" {
  type = string
}

variable "subscription-name" {
  type = string
}

variable "sub-ttl" {
  type = string
}
variable "arch-type" {
  type = string
}
variable "output_path" {
  type = string
}
variable "source_dir" {
  type = string
}
variable "bucket_obj" {
  type = string
}
variable "connector-name" {
  type = string
}
variable "connector-ip-range" {
  type = string
}

variable "cf-name" {
  type = string
}

variable "cf-description" {
  type = string
}

variable "cf-runtime" {
  type = string
}

variable "cf-entrypoint" {
  type = string
}

variable "serv-maxins-count" {
  type = number
}

variable "serv-minins-count" {
  type = number
}

variable "serv-memory" {
  type = string
}

variable "serv-timeout" {
  type = number
}

variable "serv-cpu" {
  type = string
}

variable "mailgun-apikey" {
  type = string
}

variable "egress-settings" {
  type = string
}

variable "event-trigger-type" {
  type = string
}

variable "event-retry-policy" {
  type = string
}

variable "cloud-run-role" {
  type = string
}

variable "zone" {
  type = string
}

variable "init-type" {
  type = string
}

variable "machine-type" {
  type = string
}

variable "ins-name" {
  type = string
}

variable "serv-scope" {
  type = string
}

variable "vm-tags" {
  type = string
}

variable "ssl-certificate" {
  type = string
}

variable "ssl-key" {
  type = string
}

variable "ssl-name" {
  type = string
}

variable "proxy-name" {
  type = string
}

variable "proxy-cidr" {
  type = string
}

variable "proxy-purpose" {
  type = string
}

variable "proxy-role" {
  type = string
}

variable "dir" {
  type = string
}

variable "https-port" {
  type = string
}

variable "vm-template-name" {
  type = string
}

variable "vm-template-desc" {
  type = string
}

variable "hc-name" {
  type = string
}

variable "hc-desc" {
  type = string
}

variable "hc-port-spec" {
  type = string
}

variable "hc-req-path" {
  type = string
}

variable "hc-header" {
  type = string
}

variable "gm-name" {
  type = string
}

variable "gm-base-name" {
  type = string
}

variable "gm-default" {
  type = string
}

variable "pool-name" {
  type = string
}

variable "as-name" {
  type = string
}

variable "as-mode" {
  type = string
}

variable "gca-name" {
  type = string
}

variable "gca-addr" {
  type = string
}

variable "gca-ntk" {
  type = string
}

variable "fr-name" {
  type = string
}

variable "fr-protocol" {
  type = string
}

variable "fr-scheme" {
  type = string
}

variable "fr-port" {
  type = string
}

variable "fr-tier" {
  type = string
}

variable "pt-name" {
  type = string
}

variable "um-name" {
  type = string
}

variable "bs-name" {
  type = string
}

variable "bs-scheme" {
  type = string
}

variable "bs-portname" {
  type = string
}

variable "bs-protocol" {
  type = string
}

variable "bs-session" {
  type = string
}

variable "bs-mode" {
  type = string
}

variable "keyring" {
  type = string
}

variable "vmkey" {
  type = string
}

variable "sqlkey" {
  type = string
}

variable "rotper" {
  type = string
}

variable "kmskey" {
  type = string
}

variable "encdec" {
  type = string
}
