# Defining variables
# For information on variables, check https://www.terraform.io/docs/configuration/variables.html

variable "credentials_path" {
  type        = "string"
  description = "the path to your Google Cloud json credentials file."
}

variable "project_name" {
  type        = "string"
  description = "Google Cloud project name."
}

variable "cluster_name" {
  default     = "test-k8s"
  type        = "string"
  description = "cluster name."
}

variable "cluster_region" {
  default     = "europe-west1"
  type        = "string"
  description = "The region where the cluster will be created."
}

variable "cluster_zone" {
  default     = "europe-west1-b"
  type        = "string"
  description = "The zone where the cluster will be created."
}

variable "cluster_description" {
  type        = "string"
  description = "description of the cluster and its purpose."
  default     = "Test cluster"
}

# Configure the Google Cloud provider
# For information on the providers/Google provider, check https://www.terraform.io/docs/configuration/providers.html and 
# https://www.terraform.io/docs/providers/google/index.html 
provider "google" {
  credentials = "${file(var.credentials_path)}"
  project     = "${var.project_name}"
  region      = "${var.cluster_region}"
}

# The Google cluster resource
# For all options and configurations, check https://www.terraform.io/docs/providers/google/r/container_cluster.html 
resource "google_container_cluster" "primary" {
  name        = "${var.cluster_name}"
  zone        = "${var.cluster_zone}"
  description = "${var.cluster_description}"

  network    = "default"
  subnetwork = "default"

  initial_node_count = 1

  master_auth {
    username = "admin"
    password = "my-top-secret128998908"
  }

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels {
      foo = "bar"
    }

    tags = ["foo", "bar"]
  }
}
