variable "prefix" {}
variable "location" {}
variable "pat" {}
variable "user" {}
variable "org" {}
variable "pool" {}
variable "subscription" {}
variable "subscription_service_name" {}
variable "devops_project_name" {}
variable "aks_cluster_name" {}
variable "aks_service_name" {}
variable "node_min_count"{
    default = 3
}
variable "node_max_count"{
    default = 10
}
variable "profile" {
    description = "The deployment profile, e.g., dev or prod"
    type = string
    default = "dev"
}

locals {
    size = var.profile == "dev" ? "Standard_A2_v2" : "Standard_D2_v2"
    node_size = var.profile == "dev" ? "Standard_A2_v2" : "Standard_D2_v2"
}

