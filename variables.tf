variable "resource_group_location" {
  default     = "eastus"
  description = "Location of the resource group."
 
}

variable "tags" {
  type = map(string)
  default = {
    "name" = "Owner"
    "value" = "Arnab"
  }
}



variable "resource_group_name" {
  default     = "VM-Exposure-Lab"
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "subnetid" {
  default = "Public-Sub-1"
  type = string
  description = "Resource id of Subnet"
  
}