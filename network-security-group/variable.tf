variable "port_http" {
  type        = string
  default     = "80"
  description = "Port for HTTP for Network Security Group"
}

variable "port_https" {
  type        = string
  default     = "443"
  description = "Port for HTTPS for Network Security Group"
}

variable "port_db" {
  type    = string
  default = "3306"
}

variable "subnet_names" {
  type    = list(string)
  default = ["frontend", "backend", "database"]
}