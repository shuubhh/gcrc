terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
#      version = "5.26.0"
    }
    ko = {
      source  = "ko-build/ko"
#      version = "0.15.1"
    }
    google-beta = {
      source = "hashicorp/google-beta"
      version = "5.26.0"
    }
  }
  backend "gcs" {
    bucket = "crcgcp01tfstate"
  }
}

provider "google" {
  project = var.project
  region  = var.region
}

variable "project" {
  default = "crc-gcp-01"
}

variable "region" {
  default = "asia-south1"
}

variable "service" {
  default = "tf-ko-run-service"
}



resource "google_project_service" "required_apis" {
  for_each = toset([
    "artifactregistry.googleapis.com",
    "run.googleapis.com",
    "apigateway.googleapis.com",
    "storage.googleapis.com",
    "dns.googleapis.com",
    "compute.googleapis.com",
    "certificatemanager.googleapis.com",
    "firestore.googleapis.com",
    "servicecontrol.googleapis.com",
    "servicemanagement.googleapis.com",
    "cloudapis.googleapis.com",
  ])

  project = var.project
  service = each.value
  disable_dependent_services = false
  disable_on_destroy = false

  timeouts {
    create = "30m"
    update = "40m"
  }
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

resource "google_api_gateway_gateway" "gateway" {
  provider = google-beta
  api_config = google_api_gateway_api_config.openapi_config.id
  region = "asia-northeast1"
  gateway_id = "apii-gateway"
}

#######################################################################

resource "google_storage_bucket" "pr24" {
  name = "pr24"
  location = "US"
  force_destroy = true
  
uniform_bucket_level_access = true
  
}

resource "google_storage_bucket_iam_member" "allow_public_read_pr24" {
  provider = google
  bucket   = google_storage_bucket.pr24.name
  role     = "roles/storage.objectViewer"
  member   = "allUsers"
}

resource "google_storage_bucket_object" "bshubhcv" {
  name   = "bshubhcv.pdf"
  bucket = google_storage_bucket.pr24.name
  source = "cv/bshubhCV.pdf"
  content_type = "application/pdf"
}

###############################################################

resource "google_storage_bucket" "my_bucket" {
  name          = "gcpcloudshubh"
  location      = "US"
  force_destroy = true

uniform_bucket_level_access = true

  website {
    main_page_suffix = "index.html"
   # not_found_page   = "404.html"
  }
  cors {
    origin          = ["https://storage.googleapis.com/gcpcloudshubh/"]
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
}

# Make bucket public
resource "google_storage_bucket_iam_member" "allow_public_read" {
  provider = google
  bucket   = google_storage_bucket.my_bucket.name
  role     = "roles/storage.objectViewer"
  member   = "allUsers"
}

/*
resource "google_storage_object_access_control" "allow_public" {
  object = google_storage_bucket.object.index.name
  bucket = google_storage_bucket.my_bucket.name
  role = "READER"
  entity = "allUsers"
}
*/

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

resource "google_storage_bucket_object" "boki" {
  name   = "boki.jpg"
  bucket = google_storage_bucket.my_bucket.name
  source = "images/boki.jpg"
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


resource "google_compute_global_address" "example_ip" {
  name = "example-ip"
}

data "google_dns_managed_zone" "gcp-cloudshubh" {
  provider = google
  name = "gcp-cloudshubh" 
}

resource "google_dns_record_set" "gcpsite" {
  provider = google
  name = "${data.google_dns_managed_zone.gcp-cloudshubh.dns_name}"
  type = "A"
  ttl = 300
  managed_zone = data.google_dns_managed_zone.gcp-cloudshubh.name
  rrdatas = [google_compute_global_address.example_ip.address]
  
}

resource "google_compute_backend_bucket" "site-backend" {
  provider = google
  name = "site-backend"
  description = "Contains files for website"
  bucket_name = google_storage_bucket.my_bucket.name
  enable_cdn = true  
}


resource "google_compute_managed_ssl_certificate" "lb_default" {
  provider = google-beta
  name     = "myservice-ssl-cert"

  managed {
    domains = [google_dns_record_set.gcpsite.name]
  }
}

resource "google_compute_url_map" "default" {
  provider = google
  name        = "url-map"
  description = "urlmap for site"
  default_service = google_compute_backend_bucket.site-backend.self_link

  host_rule {
    hosts        = ["gcp.cloudshubh.in"]
    path_matcher = "allpaths"
  }
/*
  host_rule {
    hosts = ["cloudshubh.in"]
    path_matcher = "redirect"
  }
*/
  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_bucket.site-backend.self_link

    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_bucket.site-backend.self_link
    }
  }
  /*

  path_matcher {
    name = "redirect"
    default_url_redirect {
      redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
      https_redirect = true
      strip_query = false
      host_redirect = "gcp.cloudshubh.in"
    }
  }*/
}


resource "google_compute_target_https_proxy" "lb_default" {
  provider = google-beta
  name     = "myservice-https-proxy"
  url_map  = google_compute_url_map.default.self_link
  ssl_certificates = [
    google_compute_managed_ssl_certificate.lb_default.self_link
  ]
  depends_on = [
    google_compute_managed_ssl_certificate.lb_default
  ]
}

resource "google_compute_http_health_check" "default" {
  name               = "http-health-check"
  request_path       = "/"
  check_interval_sec = 1
  timeout_sec        = 1
}

resource "google_compute_global_forwarding_rule" "default" {
  provider = google
  name       = "forwarding-rule"
  load_balancing_scheme = "EXTERNAL"
  ip_address = google_compute_global_address.example_ip.address
  ip_protocol = "TCP"
  port_range = "443"
  target     = google_compute_target_https_proxy.lb_default.self_link
}

resource "google_compute_url_map" "http-redirect" {
  name = "http-redirect"

  default_url_redirect {
    // "redirect_response_code" is removed
    // redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"  // 301 redirect
    strip_query            = false
    https_redirect         = true  // this is the magic
  }
}

resource "google_compute_target_http_proxy" "http-redirect" {
  name    = "http-redirect"
  url_map = google_compute_url_map.http-redirect.self_link
}

resource "google_compute_global_forwarding_rule" "http-redirect" {
  name       = "http-redirect"
  target     = google_compute_target_http_proxy.http-redirect.self_link
  ip_address = google_compute_global_address.example_ip.address
  port_range = "80"
}

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