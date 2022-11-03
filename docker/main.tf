terraform {
    required_providers {
        coder = {
            source  = "coder/coder"
            version = "0.6.0"
        }
        docker = {
            source  = "kreuzwerker/docker"
            version = "~> 2.20.2"
        }
    }
}

data "coder_provisioner" "me" {
}

provider "docker" {
}

data "coder_workspace" "me" {
}

variable "username" {
    default = "root"
}
variable "password" {
    default = "root"
}
variable "database" {
    default = "postgres"
}

resource "docker_network" "internal_network" {
    name = "coder-internal-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
    driver = "bridge"
}

resource "docker_volume" "postgres_volume" {
    name = "coder-postgres-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
}

resource "docker_image" "workspace_image" {
    name         = "coder-base-${lower(data.coder_workspace.me.owner)}-${lower(data.coder_workspace.me.name)}"
    build {
        path       = "."
        dockerfile = "./Dockerfile"
        tag        = ["coder-base-general-workspace-image:latest"]
    }
}

resource "coder_agent" "main" {
    arch           = data.coder_provisioner.me.arch
    os             = "linux"
    startup_script = <<EOT
        #!/bin/bash
        # install and start code-server
        curl -fsSL https://code-server.dev/install.sh | sh  | tee code-server-install.log
        code-server --auth none | tee code-server-install.log &
    EOT
}

resource "coder_app" "code-server" {
    agent_id     = coder_agent.main.id
    slug         = "code-server"
    display_name = "code-server"
    url          = "http://localhost:8080/?folder=/home/coder"
    icon         = "/icon/code.svg"
    subdomain    = false
    share        = "owner"

    healthcheck {
        url       = "http://localhost:8080/healthz"
        interval  = 3
        threshold = 10
    }
}

resource "docker_volume" "home_volume" {
    name = "coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}-root"
}

resource "docker_container" "workspace" {
    count = data.coder_workspace.me.start_count
    image = docker_image.workspace_image.latest
    # Uses lower() to avoid Docker restriction on container names.
    name     = "coder-${lower(data.coder_workspace.me.owner)}-${lower(data.coder_workspace.me.name)}"
    hostname = lower(data.coder_workspace.me.name)
    dns      = ["1.1.1.1"]
    # Use the docker gateway if the access URL is 127.0.0.1
    entrypoint = ["sh", "-c", replace(coder_agent.main.init_script, "/localhost|127\\.0\\.0\\.1/", "host.docker.internal")]
    env        = ["CODER_AGENT_TOKEN=${coder_agent.main.token}"]
    host {
        host = "host.docker.internal"
        ip   = "host-gateway"
    }
    volumes {
        container_path = "/home/coder/"
        volume_name    = docker_volume.home_volume.name
        read_only      = false
    }
}

resource "docker_container" "postgres" {
    name = "coder-postgres-${lower(data.coder_workspace.me.owner)}-${lower(data.coder_workspace.me.name)}"
    count = 1
    image = "postgres:latest"
    hostname = "postgres"
    volumes {
        container_path = "/var/lib/postgresql/data"
        volume_name    = docker_volume.postgres_volume.name
        read_only      = false
    }
    env = [
        "POSTGRES_USER=${var.username}",
        "POSTGRES_PASSWORD=${var.password}",
        "POSTGRES_DB=${var.database}"
    ]
    dynamic "networks_advanced" {
        for_each = docker_network.internal_network.name == "" ? [] : [1]
        content {
            name = docker_network.internal_network.name
        }
    }
}