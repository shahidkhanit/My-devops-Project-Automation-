terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# GKE Cluster for DevOps
resource "google_container_cluster" "devops_cluster" {
  name     = "devops-cluster"
  location = var.region

  remove_default_node_pool = true
  initial_node_count       = 1

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
}

resource "google_container_node_pool" "devops_nodes" {
  name       = "devops-node-pool"
  location   = var.region
  cluster    = google_container_cluster.devops_cluster.name
  node_count = 3

  node_config {
    preemptible  = false
    machine_type = "e2-medium"

    labels = {
      cluster = "devops"
      role    = "monitoring"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

# GKE Cluster for Applications
resource "google_container_cluster" "application_cluster" {
  name     = "application-cluster"
  location = var.region

  remove_default_node_pool = true
  initial_node_count       = 1

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
}

resource "google_container_node_pool" "application_nodes" {
  name       = "app-node-pool"
  location   = var.region
  cluster    = google_container_cluster.application_cluster.name
  node_count = 5

  node_config {
    preemptible  = false
    machine_type = "e2-standard-2"

    labels = {
      cluster = "application"
      role    = "workload"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}