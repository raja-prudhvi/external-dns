
variable "project_id" {
  type        = string
  description = "The project ID to create the cluster in"
}

variable "environment" {
  type        = string
  description = "The environment to create the resources in"
  default     = "dev"
}

# variable "cluster_name" {
#   type        = string
#   description = "The name of the GKE cluster"
# }

variable "domain_filters" {
  type        = list(string)
  description = "The domain name to manage DNS records for"
}

variable "app_version" {
  type        = string
  description = "The version of ExternalDNS to deploy"
  default     = "v0.13.2"
}

variable "host" {
  type        = string
  description = "The host name of the GKE cluster"
}

variable "cluster_ca_certificate" {
  type        = string
  description = "The CA certificate of the GKE cluster"
}

variable "token" {
  type = string
  description = "The token to authenticate with the GKE cluster"
}