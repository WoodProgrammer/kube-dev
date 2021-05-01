module "cluster" {
    source = "../module"
    cluster_name = "dev-cluster"
    region = "eu-west-1"
    vpc_name = "dev-vpc"
    security_group_ids = ["sg-abcde"]
    master_min_size = 1
    key_name = "cluster-keypair"
}