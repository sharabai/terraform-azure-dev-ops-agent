variable "prefix" {}
variable "location" {}
variable "pat" {}
variable "user" {}
variable "org" {}
variable "pool" {}
variable "subscription" {}
variable "devops_project_name" {}
variable "aks_cluster_name" {}
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
    size = var.profile == "dev" ? "Standard_B1s" : "Standard_D2_v2"
    node_size = var.profile == "dev" ? "Standard_A2_v2" : "Standard_D2_v2"
}

