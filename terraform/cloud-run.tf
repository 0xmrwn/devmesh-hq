resource "google_cloud_run_v2_service" "firecrawl" {
  name     = "firecrawl-service"
  location = var.default_region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {

    # ---------- global settings (apply to the whole revision) --------------
    timeout                          = "900s" # matches the 15-min idle window
    max_instance_request_concurrency = var.firecrawl_scaling.max_instance_request_concurrency

    scaling {
      min_instance_count = var.firecrawl_scaling.min_instance_count
      max_instance_count = var.firecrawl_scaling.max_instance_count
    }

    # ---------------- ingress container ------------------------------------
    containers {
      name    = "api"
      image   = var.firecrawl_container_images["api"]
      command = ["pnpm", "run", "start:production"]

      env {
        name  = "HOST"
        value = "0.0.0.0"
      }

      ports {
        container_port = var.firecrawl_container_ports["api"]
      }

      env {
        name  = "PORT"
        value = var.firecrawl_container_ports["api"]
      }
      env {
        name  = "REDIS_URL"
        value = "redis://localhost:${var.firecrawl_container_ports["redis"]}"
      }
      env {
        name  = "REDIS_RATE_LIMIT_URL"
        value = "redis://localhost:${var.firecrawl_container_ports["redis"]}"
      }
      env {
        name  = "PLAYWRIGHT_MICROSERVICE_URL"
        value = "http://localhost:${var.firecrawl_container_ports["puppeteer"]}"
      }

      env {
        name  = "MAX_RAM"
        value = "0.95"
      }

      env {
        name  = "MAX_CPU"
        value = "0.95"
      }

      env {
        name  = "NUM_WORKERS_PER_QUEUE"
        value = "2"
      }

      resources {
        limits = {
          cpu    = var.firecrawl_api_resources.cpu
          memory = var.firecrawl_api_resources.memory
        }
      }

      depends_on = ["redis", "puppeteer"] # wait until Redis reports “Ready”
    }

    # ---------------- worker sidecar ---------------------------------------
    containers {
      name    = "worker"
      image   = var.firecrawl_container_images["worker"]
      command = ["pnpm", "run", "workers"]

      env {
        name  = "HOST"
        value = "0.0.0.0"
      }

      env {
        name  = "PORT"
        value = var.firecrawl_container_ports["worker"]
      }
      env {
        name  = "REDIS_URL"
        value = "redis://localhost:${var.firecrawl_container_ports["redis"]}"
      }
      env {
        name  = "REDIS_RATE_LIMIT_URL"
        value = "redis://localhost:${var.firecrawl_container_ports["redis"]}"
      }
      env {
        name  = "PLAYWRIGHT_MICROSERVICE_URL"
        value = "http://localhost:${var.firecrawl_container_ports["puppeteer"]}"
      }

      env {
        name  = "MAX_RAM"
        value = "0.95"
      }

      env {
        name  = "MAX_CPU"
        value = "0.95"
      }

      env {
        name  = "NUM_WORKERS_PER_QUEUE"
        value = "2"
      }

      resources {
        limits = {
          cpu    = var.firecrawl_worker_resources.cpu
          memory = var.firecrawl_worker_resources.memory
        }
      }
      depends_on = ["redis", "puppeteer", "api"]
    }

    # ---------------- puppeteer sidecar ------------------------------------
    containers {
      name  = "puppeteer"
      image = var.firecrawl_container_images["puppeteer"]

      ports {
        container_port = var.firecrawl_container_ports["puppeteer"]
      }

      env {
        name  = "PORT"
        value = var.firecrawl_container_ports["puppeteer"]
      }
      env {
        name  = "MAX_CONCURRENCY"
        value = "2"
      }

      resources {
        limits = {
          cpu    = var.firecrawl_puppeteer_resources.cpu
          memory = var.firecrawl_puppeteer_resources.memory
        }
      }
    }

    # ---------------- in-memory Redis sidecar ------------------------------
    containers {
      name    = "redis"
      image   = var.firecrawl_container_images["redis"]
      command = ["redis-server", "--bind", "0.0.0.0", "--maxmemory", "128mb", "--maxmemory-policy", "allkeys-lru"]

      ports {
        container_port = var.firecrawl_container_ports["redis"]
      }

      resources {
        limits = {
          cpu    = var.firecrawl_redis_resources.cpu
          memory = var.firecrawl_redis_resources.memory
        }
      }
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
}
