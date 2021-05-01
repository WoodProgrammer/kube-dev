resource "aws_s3_bucket" "cluster_bucket" {
  bucket = "k8s-cluster-config-${var.cluster_name}"
  acl    = "private"

  versioning {
    enabled = true
  }
}