provider "google" {
  credentials = file(var.googlecred)
  project     = var.project_id
  region      = var.region
}

resource "google_compute_region_ssl_certificate" "ssl_cert" {
  name        = var.ssl-name
  certificate = file(var.ssl-certificate)
  private_key = file(var.ssl-key)
}

resource "google_compute_network" "vpc" {
  name                    = var.vpc-network
  auto_create_subnetworks = false
  routing_mode            = var.routing_mode
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "webapp_subnet" {
  name          = var.subnet-webapp
  ip_cidr_range = var.webapp-cidr
  region        = var.region
  network       = google_compute_network.vpc.self_link
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "db_subnet" {
  name          = var.subnet-db
  ip_cidr_range = var.db-cidr
  region        = var.region
  network       = google_compute_network.vpc.self_link
}

resource "google_compute_subnetwork" "proxy_only_subnet" {
  name          = var.proxy-name 
  ip_cidr_range = var.proxy-cidr
  region        = var.region
  network       = google_compute_network.vpc.self_link
  purpose       = var.proxy-purpose
  role          = var.proxy-role
}

resource "google_compute_route" "webapp_route" {
  name        = var.webapp-route
  dest_range  = var.route-config
  network     = google_compute_network.vpc.self_link
  next_hop_gateway = var.internet-gateway
}

data "google_compute_image" "latest_custom_image" {
  family  = "app-custom-image"
}

output "latest_custom_image_name" {
  value = data.google_compute_image.latest_custom_image.name
}

resource "google_compute_firewall" "allow" {
  name    = var.allow-firewall
  network = google_compute_network.vpc.self_link
  direction     = var.dir
  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = [var.application_port, var.ssh-port, var.https-port]
  }
  target_tags = ["http-server"]
  source_ranges = [google_compute_subnetwork.proxy_only_subnet.ip_cidr_range, "10.129.0.0/23", "130.211.0.0/22", "35.191.0.0/16"]
}

resource "google_compute_firewall" "deny" {
  name    = "deny-firewall"
  network = google_compute_network.vpc.self_link

  deny {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}

# Private IP Configuration
resource "google_compute_global_address" "private_ip_address" {
  name          = var.ip_name 
  project          = var.project_id
  purpose       = var.ip_purpose
  address_type  = var.ip_type
  prefix_length = 16
  network       = google_compute_network.vpc.self_link 
}

# Google Service Networking Connection
resource "google_service_networking_connection" "default" {
  network                 = google_compute_network.vpc.self_link
  service                 = var.service_name 
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

resource "google_sql_database_instance" "db_instance" {
  name             = var.db_instance_name
  project          = var.project_id
  region           = var.region

  deletion_protection = false
  depends_on = [google_service_networking_connection.default]
  database_version    = var.database_version
  settings {
    tier = var.db_tier
    disk_type = var.db_disk_type
    disk_size = var.db_size
    availability_type = var.db_availablity_type
    ip_configuration {
      ipv4_enabled = false
      private_network = google_compute_network.vpc.id
    }
  }
}

resource "google_sql_database" "webapp_db" {
  name     = var.sql_db_name
  instance = google_sql_database_instance.db_instance.name
}

resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = var.override_special
}

resource "google_sql_user" "webapp_user" {
  name     = var.sql_user_name
  instance = google_sql_database_instance.db_instance.name
  password = random_password.db_password.result
  depends_on = [google_sql_database.webapp_db]
}

resource "google_service_account" "service_account" {
  account_id   = var.service-acc-id
  display_name = var.service-acc-dispname
  project = var.project_id
}

resource "google_project_iam_binding" "logging_admin_binding" {
  project = var.project_id
  role    = var.role-logging
  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]
}

resource "google_project_iam_binding" "metric_writer_binding" {
  project = var.project_id
  role    = var.role-monitormetric
  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]
}
resource "google_project_iam_binding" "pubsub_publisher_binding" {
  project = var.project_id
  role    = var.role-publisher
  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]
}

resource "google_dns_record_set" "dns_record" {
  name        = var.dns-const
  type        = "A"
  ttl         = 30
  managed_zone = var.dns-managed-zone
  rrdatas = [google_compute_address.default.address]
}

resource "google_pubsub_topic" "verify_email" {
  project = var.project_id
  name = var.topic-name
  message_retention_duration = var.message-retention
}

resource "google_pubsub_subscription" "verify_email_subscription" {
  project = var.project_id
  name  = var.subscription-name
  topic = google_pubsub_topic.verify_email.name
  ack_deadline_seconds = 50
  message_retention_duration = var.message-retention # 7 days in seconds
  retain_acked_messages = true
  expiration_policy {
    ttl = var.sub-ttl # 31 days in seconds
  }
  enable_message_ordering = false
}


resource "random_id" "bucket_suffix" {
  byte_length = 4
}

data "archive_file" "default" {
  type        = var.arch-type
  output_path = var.output_path
  source_dir  = var.source_dir
}

resource "google_storage_bucket" "existing_bucket" {
  name     = "cloud-func-bucket-${random_id.bucket_suffix.hex}"
  location = var.region
  project  = var.project_id
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_object" "existing_object" {
  name   = var.bucket_obj
  bucket = google_storage_bucket.existing_bucket.name
  source = data.archive_file.default.output_path
}

resource "google_vpc_access_connector" "vpc-connector" {
  name    = var.connector-name
  network = google_compute_network.vpc.self_link
  region  = var.region
  ip_cidr_range = var.connector-ip-range
}

resource "google_cloudfunctions2_function" "verify_func" {
  project = var.project_id
  name        = var.cf-name
  location    = var.region
  description = var.cf-description
  build_config {
    runtime     = var.cf-runtime
    entry_point =  var.cf-entrypoint # Set the entry point
    source {
      storage_source {
        bucket = google_storage_bucket.existing_bucket.name
        object = google_storage_bucket_object.existing_object.name
      }
    }
  }

  service_config {
    max_instance_count = var.serv-maxins-count
    min_instance_count = var.serv-minins-count
    available_memory   = var.serv-memory
    timeout_seconds    = var.serv-timeout
    available_cpu      = var.serv-cpu
    environment_variables = {
      DB_HOST     = "${google_sql_database_instance.db_instance.ip_address.0.ip_address}"
      DB_PORT     = "${var.postgres_port}"
      DB_USER     = "${google_sql_user.webapp_user.name}"
      DB_PASSWORD = "${random_password.db_password.result}"
      DB_DATABASE = "${google_sql_database.webapp_db.name}"
      MAILGUN_API_KEY = var.mailgun-apikey
    }
    service_account_email = google_service_account.pubsub_service_account.email
    vpc_connector = google_vpc_access_connector.vpc-connector.name
    vpc_connector_egress_settings = var.egress-settings
  }
 
  event_trigger {
    trigger_region = var.region
    service_account_email = google_service_account.pubsub_service_account.email
    event_type = var.event-trigger-type
    pubsub_topic = google_pubsub_topic.verify_email.id
    retry_policy   = var.event-retry-policy
  }

  depends_on = [google_sql_database_instance.db_instance, google_pubsub_topic.verify_email, google_storage_bucket.existing_bucket, google_storage_bucket_object.existing_object]
}

resource "google_service_account" "pubsub_service_account" {
  account_id   = var.pub-service-acc-id
  display_name = var.pub-service-acc-dispname
  project = var.project_id
}

resource "google_cloud_run_service_iam_member" "member" {
  location = google_cloudfunctions2_function.verify_func.location
  service  = google_cloudfunctions2_function.verify_func.name
  role     = var.cloud-run-role
  project = google_cloudfunctions2_function.verify_func.project
  member = "serviceAccount:${google_service_account.pubsub_service_account.email}"
  depends_on = [ google_cloudfunctions2_function.verify_func,  google_service_account.pubsub_service_account]
}

resource "google_compute_region_instance_template" "vm-instance-template" {
  name = var.vm-template-name
  description = var.vm-template-desc
  tags = [var.vm-tags]
  machine_type = var.machine-type
  depends_on = [ google_compute_firewall.allow, google_compute_subnetwork.webapp_subnet, google_service_account.service_account]
  disk {
    source_image = data.google_compute_image.latest_custom_image.self_link
    type  = var.init-type
  }
  service_account {
    email  = google_service_account.service_account.email
    scopes = [var.serv-scope]
  }
  lifecycle {
    create_before_destroy = true
  }
  network_interface {
    access_config {
    }
    network = google_compute_network.vpc.self_link
    subnetwork  = google_compute_subnetwork.webapp_subnet.self_link
  }
  metadata_startup_script = <<-EOT
    #!/bin/bash
    set -e

    env_file="/opt/webapp/.env"
    echo "DB_HOST=${google_sql_database_instance.db_instance.ip_address.0.ip_address}" > "$env_file"
    echo "DB_PORT=${var.postgres_port}" >> "$env_file"
    echo "DB_USER=${google_sql_user.webapp_user.name}" >> "$env_file"
    echo "DB_NAME=${google_sql_database.webapp_db.name}" >> "$env_file"
    echo "DB_PASSWORD=${random_password.db_password.result}" >> "$env_file"
    echo "DB_DIALECT=${var.postgres_dialect}" >> "$env_file"
    echo "PUBSUB_TOPIC_NAME= projects/preeticloud/topics/${google_pubsub_topic.verify_email.name}" >> "$env_file"
  EOT
}

resource "google_compute_region_health_check" "http-health-check" {
  name        = var.hc-name
  description = var.hc-desc
  region = var.region
  timeout_sec         = 5
  check_interval_sec  = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2

  http_health_check {
    port_specification = var.hc-port-spec
    port               = var.application_port
    request_path       = var.hc-req-path
    proxy_header       = var.hc-header
  }
}

resource "random_id" "instance_group_suffix" {
  byte_length = 4
}

resource "google_compute_region_instance_group_manager" "instance_group" {
  name = var.gm-name
  base_instance_name         = var.gm-base-name
  region                     = var.region
  distribution_policy_zones = ["us-central1-a", "us-central1-b", "us-central1-c", "us-central1-f"]
  version {
    instance_template = google_compute_region_instance_template.vm-instance-template.self_link
  }
  target_pools = [google_compute_target_pool.foobar.id]
  target_size  = 2
  named_port {
    name = "http"
    port = 3000
  }
  auto_healing_policies {
    health_check      = google_compute_region_health_check.http-health-check.id
    initial_delay_sec = 300
  }
  instance_lifecycle_policy {
    force_update_on_repair    = "NO"
    default_action_on_failure = "REPAIR"
  }
  depends_on = [google_compute_region_instance_template.vm-instance-template]
}

resource "google_compute_target_pool" "foobar" {
  name = var.pool-name
}

resource "google_compute_region_autoscaler" "instance_autoscaler" {
  name   = var.as-name
  region = var.region
  target = google_compute_region_instance_group_manager.instance_group.id

  autoscaling_policy {
    max_replicas    = 8
    min_replicas    = 4
    cooldown_period = 180
    mode            = var.as-mode

    cpu_utilization {
      target = 0.1
    }
  }
}

resource "google_compute_address" "default" {
  name         = var.gca-name
  address_type = var.gca-addr
  network_tier = var.gca-ntk
  region       = var.region
}

# forwarding rule
resource "google_compute_forwarding_rule" "forwarding_rule" {
  region = var.region
  name                  = var.fr-name
  depends_on = [google_compute_subnetwork.proxy_only_subnet]
  ip_protocol           = var.fr-protocol
  load_balancing_scheme = var.fr-scheme
  port_range            = var.fr-port
  network               = google_compute_network.vpc.id
  target                = google_compute_region_target_https_proxy.target_proxy.id
  ip_address            = google_compute_address.default.id
  network_tier          = var.fr-tier
}

resource "google_compute_region_target_https_proxy" "target_proxy" {
  name             = var.pt-name
  url_map          = google_compute_region_url_map.url_map.id
  ssl_certificates   = [google_compute_region_ssl_certificate.ssl_cert.id]
  depends_on = [google_compute_region_ssl_certificate.ssl_cert]
}

resource "google_compute_region_url_map" "url_map" {
  name            = var.um-name
  region = var.region
  default_service = google_compute_region_backend_service.backend_service.id
}

resource "google_compute_region_backend_service" "backend_service" {
  name        = var.bs-name
  region = var.region
  load_balancing_scheme = var.bs-scheme
  port_name   = var.bs-portname
  protocol    = var.bs-protocol
  session_affinity      = var.bs-session
  timeout_sec = 10

  health_checks = [google_compute_region_health_check.http-health-check.id]

  backend {
    group              = google_compute_region_instance_group_manager.instance_group.instance_group
    balancing_mode     = var.bs-mode
    capacity_scaler    = 1.0
  }
}