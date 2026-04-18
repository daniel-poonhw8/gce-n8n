provider "google" {
  project = "YOUR_PROJECT_ID" # Students will replace this or use a variable
  region  = "us-central1"
}

resource "google_compute_instance" "n8n_vm" {
  name         = "n8n-student-instance"
  machine_type = "e2-small"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
    }
  }

  network_interface {
    network = "default"
    access_config {
      network_tier = "STANDARD"
    }
  }

  scheduling {
    preemptible        = true
    provisioning_model = "SPOT"
    automatic_restart  = false
  }

  # This automates the setup so students don't have to run manual commands
  metadata_startup_script = <<-EOT
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install -y docker.io
    sudo systemctl enable --now docker
    mkdir -p /home/ubuntu/n8n-data
    chown -R 1000:1000 /home/ubuntu/n8n-data
    # Optional: Pre-pull the n8n image to save time
    docker pull n8nio/n8n:latest
  EOT
}
