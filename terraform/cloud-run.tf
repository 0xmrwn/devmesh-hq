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
        name  = "TEST_API_KEY"
        value = "fc-${random_password.firecrawl_api_key.result}"
      }

      resources {
        limits = {
          cpu    = "0.25"
          memory = "256Mi"
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

      resources {
        limits = {
          cpu    = "0.25"
          memory = "256Mi"
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
          cpu    = "0.5"
          memory = "512Mi"
        }
      }
    }

    # ---------------- in-memory Redis sidecar ------------------------------
    containers {
      name    = "redis"
      image   = var.firecrawl_container_images["redis"]
      command = ["redis-server", "--bind", "0.0.0.0"]

      ports {
        container_port = var.firecrawl_container_ports["redis"]
      }

      resources {
        limits = {
          cpu    = "0.05"
          memory = "128Mi"
        }
      }
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
}
