# ExternalDNS will need permissions to make changes to the Cloud DNS zone. There are three ways to configure the access needed:

# 1. Worker Node Service Account
# 2. Static Credentials
# 3. Work Load Identity

# we shall proceed with work load identity for now
#https://raw.githubusercontent.com/boredabdel/useful-k8s-stuff/main/external-dns-gcp.yaml


data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = var.host
  cluster_ca_certificate = var.cluster_ca_certificate
  token                  = var.token
}

provider "kubectl" {
  host                   = var.host
  cluster_ca_certificate = var.cluster_ca_certificate
  token                  = var.token
  load_config_file       = false
}

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source = "hashicorp/google"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

locals {
  name = "external-dns"
  domain_filter = concat([
    "--source=service",
    "--source=ingress",
    "--source=istio-gateway", # --source=istio-gateway is added to support istio gateway
    "--source=istio-virtualservice", # --source=istio-virtualservice is added to support istio virtualservice
    # u dont need to add the above line, there might be a duplication of dns records created so adding at 
    # istio-gateway level is enough
    ],
    [for domain in var.domain_filters : "--domain-filter=${domain}"],
    [
      "--provider=google",
      "--google-project=${var.project_id}",
      "--registry=txt",
      "--txt-owner-id=${var.project_id}",
  ])
}


# create a namespace for external-dns
resource "kubernetes_namespace" "external_dns" {
  metadata {
    name = local.name
  }
}

# workload identity for external-dns
# Workload Identity is the recommended way to access GCP services from Kubernetes.

# This module creates:

# IAM Service Account binding to roles/iam.workloadIdentityUser
# Optionally, a Google Service Account
# Optionally, a Kubernetes Service Account

module "my-app-workload-identity" {
  source     = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  name       = "external-dns"
  namespace  = kubernetes_namespace.external_dns.metadata[0].name
  project_id = var.project_id
  roles      = ["roles/dns.admin"]

  automount_service_account_token = true
}

resource "kubernetes_cluster_role_v1" "external_dns" {
  metadata {
    name = local.name
  }

  rule {
    api_groups = [""]
    resources  = ["services", "endpoints", "pods", "nodes"]
    verbs      = ["get", "watch", "list"]
  }

  rule {
    api_groups = ["extensions", "networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get", "watch", "list"]
  }

  rule {
    api_groups = ["networking.istio.io"]
    resources  = ["gateways", "virtualservices"]
    verbs      = ["get","watch","list"]
  }

}

resource "kubernetes_cluster_role_binding_v1" "external_dns" {
  metadata {
    name = local.name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.external_dns.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = local.name
    namespace = kubernetes_namespace.external_dns.metadata[0].name
  }
}

# create a deployment for external-dns in the namespace created above,
# also add resource requests and limits for the deployment along with liveness and readiness probes , 
# also add the service account created above to the deployment

resource "kubernetes_deployment_v1" "external_dns" {
  metadata {
    name      = local.name
    namespace = kubernetes_namespace.external_dns.metadata[0].name
  }

  spec {
    replicas = 2 # we want to have 2 replicas of external-dns, so we can honor the pod disruption budget

    selector {
      match_labels = {
        app = local.name
      }
    }

    template {
      metadata {
        labels = {
          app = local.name
        }
      }

      spec {
        service_account_name = module.my-app-workload-identity.k8s_service_account_name

        container {
          name  = local.name
          image = "k8s.gcr.io/external-dns/external-dns:${var.app_version}"
          args  = local.domain_filter

          # Resource Requests and Limits
          resources {
            requests = {
              cpu    = "70m"
              memory = "150Mi"
            }
            limits = {
              cpu    = "120m"
              memory = "180Mi"
            }
          }

          security_context {
            allow_privilege_escalation = false
            capabilities {
              drop = ["ALL"]
            }
            read_only_root_filesystem = true
            run_as_non_root           = true
            seccomp_profile {
              type = "RuntimeDefault"
            }
          }

        #   # Liveness Probe
        #   liveness_probe {
        #     http_get {
        #       path = "/healthz"
        #       port = 8080
        #     }
        #     initial_delay_seconds = 5
        #     period_seconds        = 10 # Adjusted for a longer check interval
        #   }

        #   # Readiness Probe
        #   readiness_probe {
        #     http_get {
        #       path = "/healthz"
        #       port = 8080
        #     }
        #     initial_delay_seconds = 5
        #     period_seconds        = 10 # Adjusted for a longer check interval
        #     failure_threshold     = 6
        #     success_threshold     = 1
        #     timeout_seconds       = 5
        #   }
        }
      }
    }
  }
}

# pod disruption budget for external-dns
resource "kubernetes_pod_disruption_budget_v1" "external_dns" {
  metadata {
    name      = local.name
    namespace = kubernetes_namespace.external_dns.metadata[0].name
  }

  spec {
    max_unavailable = 1
    selector {
      match_labels = {
        app = local.name
      }
    }
  }
}

resource "kubectl_manifest" "hpa" {
  yaml_body = <<-EOT
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: ${local.name}-hpa
  namespace: ${kubernetes_namespace.external_dns.metadata[0].name}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: ${kubernetes_deployment_v1.external_dns.metadata[0].name}
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 90
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 90
EOT
}

