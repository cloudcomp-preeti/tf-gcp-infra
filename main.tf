provider "google" {
  credentials = file("./google-cred.json")
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
  name    = "allow-firewall"
  network = google_compute_network.vpc.self_link

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = [var.application_port]
  }
  target_tags = ["http-server"]
  source_ranges = ["0.0.0.0/0"]
  
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


resource "google_compute_instance" "vm-instance" {
  boot_disk {
    initialize_params {
      image = data.google_compute_image.latest_custom_image.self_link // var.instance_image
      size  = 100
      type  = "pd-balanced"
    }
  }
  machine_type = "e2-medium" //var.machine_type
  name         = "vm-instance" // var.name

  network_interface {
    access_config {
    }
    network = google_compute_network.vpc.self_link
    subnetwork  = google_compute_subnetwork.webapp_subnet.self_link
  }
  zone = "us-west1-b"
  tags = ["http-server"]
  depends_on = [ google_compute_firewall.allow, google_compute_subnetwork.webapp_subnet ]
}
