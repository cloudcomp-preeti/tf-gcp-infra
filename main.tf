provider "google" {
  credentials = file("./google-cred.json")
  project     = var.project_id
  region      = var.region
}

 "google_compute_network" "vpc" {
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
