# 🌐 ExternalDNS Setup for Kubernetes 🌐

Welcome to the ExternalDNS setup repository! This Terraform module installs ExternalDNS into a Kubernetes cluster, allowing for automatic DNS record management and synchronization with various cloud DNS providers.

## 🚀 Features

- **Automatic DNS Management**: ExternalDNS automatically manages DNS records based on Kubernetes resources such as Services, Ingresses, and Istio gateways and virtual services.
- **Support for Multiple Providers**: Supports integration with various cloud DNS providers including Google Cloud DNS, AWS Route 53, Azure DNS, and more.
- **Workload Identity**: Utilizes Workload Identity for secure access to GCP services from Kubernetes clusters.
- **Scalable Deployment**: Easily scalable deployment with replicas and horizontal pod autoscaling.
- **Customizable DNS Policies**: Configure custom DNS policies to define how ExternalDNS manages DNS records, including TTL settings and record filtering.
- **Integration with External Sources**: Supports integration with external sources such as Prometheus and Grafana for monitoring and visualization of DNS metrics.
- **Dynamic DNS Updates**: ExternalDNS continuously monitors Kubernetes resources and updates DNS records dynamically to reflect changes in the cluster.

## 📁 Project Structure

```
.
├── README.md
├── main.tf
├── outputs.tf
└── variables.tf

```

## 🚀 Getting Started

1. **Install Terraform**: Make sure you have Terraform installed locally.
2. **Customize Variables**: Modify the variables in `variables.tf` as per your Kubernetes environment and requirements.
3. **Run Terraform**: Execute `terraform init` to initialize Terraform, then `terraform apply` to apply the changes and install ExternalDNS.

## 🌟 Importance of ExternalDNS

ExternalDNS plays a crucial role in managing DNS records dynamically for Kubernetes clusters. Here's why it's essential:

- **Automatic DNS Management**: ExternalDNS automates the creation and deletion of DNS records based on changes to Kubernetes resources, ensuring accurate DNS resolution.
- **Simplified DNS Configuration**: Eliminates the need for manual DNS configuration, reducing human error and ensuring consistent DNS settings across the cluster.
- **Enhanced Scalability**: With features like replicas and horizontal pod autoscaling, ExternalDNS ensures scalability to handle growing workloads and traffic demands.