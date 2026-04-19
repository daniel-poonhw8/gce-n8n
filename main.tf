provider "google" {
  project = var.project_id
  region  = "us-central1"
}

variable "project_id" {
  type = string
}

# 1. THE GATE (Firewall)
resource "google_compute_firewall" "n8n_firewall" {
  name    = "allow-n8n-web-ui"
  network = "default"

  allow {
    protocol = "tcp"
    # Port 80/443 for HTTPS certificate & Telegram, 5678 for dashboard
    ports    = ["80", "443", "5678"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["n8n-node"] 
}

# 2. THE SERVER (VM)
resource "google_compute_instance" "n8n_vm" {
  name         = "n8n-server"
  machine_type = "e2-small"
  zone         = "us-central1-a"
  
  # Crucial: This links the VM to the Firewall above
  tags         = ["n8n-node"] 

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

  # REMOVED PREEMPTIBLE/SPOT BLOCK
  # Default is now On-Demand (Reliable for Class)

  metadata_startup_script = <<-EOT
    #!/bin/bash
    # Create 2GB Swap (Ensures n8n doesn't crash on small RAM)
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab

    # Install Docker
    apt-get update && apt-get install -y docker.io
    systemctl enable --now docker

    # Prepare persistent data folder
    mkdir -p /home/ubuntu/n8n-data
    chown -R 1000:1000 /home/ubuntu/n8n-data
  EOT
}
