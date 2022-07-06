/*variable "enable_blue_env" {
  description = "Enable Blue Environment"
  type = bool
  default = true
}

variable "enable_green_env" {
  description = "Enable Green Environment"
  type = bool
  default = true
}

variable "traffic_distribution" {
    description = "Level of Traffic Distribution"
    type = string
}
*/

variable "username" {
  description = "The username for the DB master user"
  type        = string

}

variable "password" {
  description = "The password for the DB master user"
  type        = string
}