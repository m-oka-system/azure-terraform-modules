variable "common" {
  type = map(string)
  default = {
    project  = "terraform"
    env      = "dev"
    location = "japaneast"
  }
}
