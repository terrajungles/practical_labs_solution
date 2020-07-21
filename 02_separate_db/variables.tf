variable "environment" {
  type    = string
  default = "dev"
}

variable "db_port" {
  type = number
  default = 27017
}

variable "app_id" {
  type = string
}

variable "master_key" {
  type = string
}
