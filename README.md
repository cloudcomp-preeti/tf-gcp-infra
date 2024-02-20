demo
# Google Cloud Platform Setup Guide

## Enabled GCP Service APIs

- **Compute Engine API**
  - API Name: compute.googleapis.com

- **Cloud OS Login API**
  - API Name: oslogin.googleapis.com

## Google Cloud Platform Networking Setup

Setting up networking infrastructure on Google Cloud Platform involves creating a Virtual Private Cloud (VPC) and configuring subnets.

### Created Virtual Private Cloud (VPC)

1. Disabled auto-creation of subnets.
2. Set routing mode to regional.
3. Did not create default routes.

### Created Subnets

1. Created two subnets within your VPC:
   - Subnet 1: Named "webapp", with a /24 CIDR address range.
   - Subnet 2: Named "db", with a /24 CIDR address range.

### Added Routes to Internet Gateway

Added a route explicitly to `0.0.0.0/0` with the next hop set to the Internet Gateway, and attached it to VPC.
This allows outbound internet access for resources within the VPC.

### Added Vars file

To keep track of variables to reduce any kind of hard coding in the configuration file.

## To run the project

```

terraform init
terraform plan -var-file="variables.tfvars" 
terraform apply -var-file="variables.tfvars" 

```
