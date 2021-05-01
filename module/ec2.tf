resource "aws_launch_configuration" "master_launch_config" {
  name_prefix   = "k8s-master-${var.cluster_name}-master"
  image_id      = "${var.ami_id}"
  instance_type = var.instance_type
  key_name = var.key_name
  security_groups = var.security_group_ids
  user_data = base64encode(data.template_file.master_script.rendered)
  iam_instance_profile = aws_iam_instance_profile.instance_profile.arn

}

resource "aws_launch_configuration" "worker_launch_config" {
  name_prefix   = "k8s-worker-${var.cluster_name}-master"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name = var.key_name
  security_groups = var.security_group_ids
  user_data = base64encode(data.template_file.worker_script.rendered)
  iam_instance_profile = aws_iam_instance_profile.instance_profile.arn

}

resource "aws_autoscaling_group" "bar" {
  name                 = "k8s-master-${var.cluster_name}-asg"
  launch_configuration = aws_launch_configuration.master_launch_config.name
  min_size             = var.master_min_size
  max_size             = var.master_min_size
  vpc_zone_identifier = data.subnet_ids.ids

  lifecycle {
    create_before_destroy = true
  }
  tag {
    key                 = "kubernetes.io/cluster/k8s-${var.cluster_name}-cluster"
    value               = "k8s-${var.cluster_name}-cluster"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "worker_asg" {
  name                 = "k8s-worker-${var.cluster_name}-asg"
  launch_configuration = aws_launch_configuration.worker_launch_config.name
  min_size             = var.worker_min_size
  max_size             = var.worker_max_size
  vpc_zone_identifier = data.subnet_ids.ids

  lifecycle {
    create_before_destroy = true
  }
  tag {
    key                 = "kubernetes.io/cluster/k8s-${var.cluster_name}-cluster"
    value               = "k8s-${var.cluster_name}-cluster"
    propagate_at_launch = true
  }
  
}