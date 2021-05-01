variable "cluster_name" {
    type = string
    description = "(optional) describe your variable"
    default = "dev-cluster"
}

variable "ami_id" {
    default = "ami-08bac620dc84221eb"
}

variable "instance_type" {
    default = "t2.medium"
}

variable "region" {
    default = "eu-west-1"
}

variable "master_min_size" {
    default = 1
}

variable "worker_min_size" {
    default = 1
}

variable "key_name"{
    default = "cluster-keypair"
}

variable "security_group_ids" {
    description = "['sg-xyz']"
}