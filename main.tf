provider "google" {
  credentials = file(var.googlecred)
  project     = var.project_id
  region      = var.region
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

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = [var.application_port, var.postgres-port, var.ssh-port]
  }
  target_tags = ["http-server"]
  source_ranges = ["0.0.0.0/0", google_compute_subnetwork.webapp_subnet.ip_cidr_range]
  
}

# resource "google_compute_firewall" "deny" {
#   name    = "deny-firewall"s
#   network = google_compute_network.vpc.self_link

#   deny {
#     protocol = "tcp"
#     ports    = ["22"]
#   }
#   source_ranges = ["0.0.0.0/0"]
# }

# Private IP Configuration
resource "google_compute_global_address" "private_ip_address" {
  name          = var.ip_name 
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

resource "google_dns_record_set" "dns_record" {
  name        = "preetikulk.me."
  type        = "A"
  ttl         = 2
  managed_zone = "cloud-zone"
  rrdatas = [
    google_compute_instance.vm-instance.network_interface.0.access_config.0.nat_ip,
  ]
}

resource "google_compute_instance" "vm-instance" {
  boot_disk {
    initialize_params {
      image = data.google_compute_image.latest_custom_image.self_link
      size  = 100
      type  = "pd-balanced"
    }
  }
  machine_type = "e2-medium"
  name         = "vm-instance"

  network_interface {
    access_config {
    }
    network = google_compute_network.vpc.self_link
    subnetwork  = google_compute_subnetwork.webapp_subnet.self_link
  }

  service_account {
    email  = google_service_account.service_account.email
    scopes = ["cloud-platform"]
  }

  zone = "us-west1-b"
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
  EOT
  tags = ["http-server"]
  depends_on = [ google_compute_firewall.allow, google_compute_subnetwork.webapp_subnet, google_service_account.service_account]
}
