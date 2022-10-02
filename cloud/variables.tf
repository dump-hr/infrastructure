variable "vm_image_id" {
  default = "/subscriptions/ab7e6915-04d4-465e-b5a6-921be601697f/resourceGroups/nixos-images/providers/Microsoft.Compute/images/nixos-image"
}

variable "deploy_password" {
  sensitive = true
}