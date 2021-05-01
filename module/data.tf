data "template_file" "master_script" {
template = file("./user_data/user_data.tpl")
    vars = {
        instance_role   = "master"
        region = var.region
        cluster_config_bucket = "k8s-cluster-config-${var.cluster_name}"
        cluster_name = "${var.cluster_name}"

    }
}

data "template_file" "worker_script" {
template = file("./user_data/user_data.tpl")
    vars = {
        instance_role   = "worker"
        region = var.region
        cluster_config_bucket = "k8s-cluster-config-${var.cluster_name}"
        cluster_name = var.cluster_name

    }
}

data "aws_vpc" "vpc_addr" {
  tags = {
      "Name" = var.vpc_name
  }
}

data "aws_subnet_ids" "subnet_ids" {
  vpc_id = data.vpc_addr.id
}