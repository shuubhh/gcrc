terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
    }
    ko = {
      source  = "ko-build/ko"
    }
    google-beta = {
      source = "hashicorp/google-beta"
      version = "5.26.0"
    }
  }
  backend "gcs" {
    bucket = "gcrc01tfstate"
  }
}

provider "google" {
  project = var.project
  region  = var.region
}

variable "project" {
  default = "gcrc01"
}

variable "region" {
  default = "asia-south1"
}

variable "service" {
  default = "tf-ko-test01"
}

resource "google_artifact_registry_repository" "example-repo" {
  location      = "asia-south1"
  repository_id = "example"
  description   = "example repository"
  format        = "DOCKER"
}

provider "ko" {}

resource "ko_build" "test01" {
  importpath = "./api.go"
}

resource "google_cloud_run_service" "default" {
  name     = var.service
  location = var.region

  template {
    spec {
      containers {
        image = ko_build.test01.image_ref
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location = google_cloud_run_service.default.location
  project  = google_cloud_run_service.default.project
  service  = google_cloud_run_service.default.name

  policy_data = data.google_iam_policy.noauth.policy_data
}

output "url" {
  value = google_cloud_run_service.default.status[0].url
}

###############################
#provider "google" {
#  project = var.project
#  region  = var.region
#}

resource "google_api_gateway_api" "my_api" {
  provider = google-beta

  display_name = "apii"
  api_id = "apii"
}

resource "google_api_gateway_api_config" "openapi_config" {
  provider = google-beta
  api   = google_api_gateway_api.my_api.api_id
  api_config_id = "apii-config"

  openapi_documents {
    document {
      path = "/spec.yaml"
      contents = filebase64("spec.yaml")
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}
/*
resource "google_api_gateway_api_config_iam_binding" "binding" {
  provider = google-beta
  api = google_api_gateway_api_config.api_cfg.api
  api_config = google_api_gateway_api_config.api_cfg.api_config_id
  role = "roles/apigateway.viewer"
  members = [
    "api-go@civic-replica-421010.iam.gserviceaccount.com",
  ]
}

resource "google_api_gateway_api_iam_binding" "binding" {
  provider = google-beta
  project = google_api_gateway_api.api.project
  api = google_api_gateway_api.api.api_id
  role = "roles/apigateway.viewer"
  members = [
    "api-go@civic-replica-421010.iam.gserviceaccount.com",
  ]
}*/

resource "google_api_gateway_gateway" "gateway" {
  provider = google-beta
  api_config = google_api_gateway_api_config.openapi_config.id
  region = "asia-northeast1"
  gateway_id = "apii-gateway"
}

#######################################################################

/*
resource "google_storage_bucket_access_control" "public_rule" {
  bucket = google_storage_bucket.my_bucket.name
  role   = "READER"
  entity = "allUsers"
}
*/

resource "google_storage_bucket" "my_bucket" {
  name          = "cloudshubh.in"
  location      = "US"
  force_destroy = true

uniform_bucket_level_access = true

  website {
    main_page_suffix = "index.html"
   # not_found_page   = "404.html"
  }
  cors {
    origin          = ["https://storage.googleapis.com/cloudshubh.in/"]
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
}

# Make bucket public
resource "google_storage_bucket_iam_member" "member" {
  provider = google
  bucket   = google_storage_bucket.my_bucket.name
  role     = "roles/storage.objectViewer"
  member   = "allUsers"
}




resource "google_storage_bucket_object" "index" {
  name   = "index.html" 
  bucket = google_storage_bucket.my_bucket.name
  source = "index.html"
  content_type = "text/html"
}

resource "google_storage_bucket_object" "script" {
  name   = "script.js"
  bucket = google_storage_bucket.my_bucket.name
  source = "script.js"
  content_type = "text/js"
}

resource "google_storage_bucket_object" "style" {
  name   = "style.css"
  bucket = google_storage_bucket.my_bucket.name
  source = "style.css"
  content_type = "text/css"
}

resource "google_storage_bucket_object" "profile" {
  name   = "profile.jpg"
  bucket = google_storage_bucket.my_bucket.name
  source = "images/profile.jpg"
  content_type = "image/jpg"
}

resource "google_storage_bucket_object" "scroll" {
  name   = "scroll-top-img.png"
  bucket = google_storage_bucket.my_bucket.name
  source = "images/scroll-top-img.png"
  content_type = "image/png"
}

resource "google_storage_bucket_object" "crdtf" {
  name   = "creatinganddestroyingterraform.jpeg"
  bucket = google_storage_bucket.my_bucket.name
  source = "images/creatinganddestroyingterraform.jpeg"
  content_type = "image/jpeg"
}

resource "google_storage_bucket_object" "crc" {
  name   = "crc.png"
  bucket = google_storage_bucket.my_bucket.name
  source = "images/crc.png"
  content_type = "image/png"
}

resource "google_storage_bucket_object" "ccp" {
  name   = "awsccp.png"
  bucket = google_storage_bucket.my_bucket.name
  source = "images/aws-certified-cloud-practitioner.png"
  content_type = "image/png"
}

/*
resource "google_compute_global_address" "default" {
  name = "example-ip"
}
*/
/*
resource "google_compute_managed_ssl_certificate" "lb_default" {
  provider = google-beta
  name     = "myservice-ssl-cert"

  managed {
    domains = ["cloudshubh.in", "www.cloudshubh.in"]
  }
}

resource "google_compute_target_https_proxy" "lb_default" {
  provider = google-beta
  name     = "myservice-https-proxy"
  url_map  = google_compute_url_map.default.id
  ssl_certificates = [
    google_compute_managed_ssl_certificate.lb_default.name
  ]
  depends_on = [
    google_compute_managed_ssl_certificate.lb_default
  ]
}

# Create LB backend buckets
resource "google_compute_backend_bucket" "my_bucket" {
  name        = "staticsite"
  description = "Contains docs and image"
  bucket_name = google_storage_bucket.my_bucket.name
}

resource "google_compute_url_map" "default" {
  name        = "url-map"
  description = "a description"

  default_service = google_compute_backend_bucket.my_bucket.id

  host_rule {
    hosts        = ["cloudshubh.in"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_bucket.my_bucket.id

    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_bucket.my_bucket.id
    }
  }
}

resource "google_compute_http_health_check" "default" {
  name               = "http-health-check"
  request_path       = "/"
  check_interval_sec = 1
  timeout_sec        = 1
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = "forwarding-rule"
  target     = google_compute_target_https_proxy.lb_default.id
  port_range = 443
}
*/

resource "google_firestore_database" "database" {
  project     = var.project
  name        = "(default)"
  location_id = "nam5"
  type        = "FIRESTORE_NATIVE"
  point_in_time_recovery_enablement = "POINT_IN_TIME_RECOVERY_ENABLED"

}

resource "google_firestore_document" "mydoc" {
  project     = var.project
  database    = google_firestore_database.database.name
  collection  = "counters"
  document_id = "counter"
  fields      = "{\"value\":{\"integerValue\":1}}"
}