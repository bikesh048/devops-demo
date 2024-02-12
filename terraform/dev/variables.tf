variable "ami_id" {
  description = "ami id"
  default     = "ami-0e731c8a588258d0d"
}

variable "instance_type" {
  description = "The EC2 instance type for the launch configuration."
  default     = "t2.micro"
}

variable "ssh_key" {
  description = "ssh key name"
  default     = "demo-app"
}