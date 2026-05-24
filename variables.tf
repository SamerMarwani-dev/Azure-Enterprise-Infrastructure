variable "location" {
  description = "The target Azure region for all enterprise resources"
  type        = string
  default     = "East US"
}

variable "rg_name" {
  description = "The name of the production resource group"
  type        = string
  default     = "Production-Enterprise-RG"
}

variable "vnet_cidr" {
  description = "The core CIDR block for the Virtual Network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "web_subnet_cidr" {
  description = "The CIDR block for the frontend public web tier"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "app_subnet_cidr" {
  description = "The CIDR block for the isolated application business logic tier"
  type        = list(string)
  default     = ["10.0.2.0/24"]
}