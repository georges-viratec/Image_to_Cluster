packer {
  required_plugins {
    docker = {
      version = ">= 1.0.8"
      source  = "github.com/hashicorp/docker"
    }
  }
}

# Variables pour personnaliser le nom et tag de l'image
variable "image_name" {
  type    = string
  default = "custom-nginx-app"
}

variable "image_tag" {
  type    = string
  default = "latest"
}

# Source : image de base Docker
source "docker" "nginx" {
  image  = "nginx:alpine"
  commit = true
  changes = [
    "EXPOSE 80",
    "CMD [\"nginx\", \"-g\", \"daemon off;\"]"
  ]
}

# Build : processus de construction
build {
  name = "nginx-custom-build"
  
  sources = ["source.docker.nginx"]

  # Copie du fichier index.html dans l'image
  provisioner "file" {
    source      = "index.html"
    destination = "/usr/share/nginx/html/index.html"
  }

  # Tag de l'image finale
  post-processor "docker-tag" {
    repository = var.image_name
    tags       = [var.image_tag]
  }
}