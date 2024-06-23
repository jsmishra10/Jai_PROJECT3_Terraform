variable "profile" {
    default = "jai-assignment"
  
}

variable "region" {
    default = "us-east-1"
  
}

variable "ami-id" {
    default = "ami-08a0d1e16fc3f61ea"
  
}

variable "instance-type" {
    default = "t2.micro"
  
}

variable "key_name" {
    default = null
  
}

variable "health_check_type" {
    default = "ELB"
  
}
