variable "github_org" {
  type    = string
  default = "MaskINB"
}

variable "github_repo" {
  type    = string
  default = "microservices-demo"
}

variable "tags" {
  type    = map(string)
  default = {}
}