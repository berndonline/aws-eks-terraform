data "aws_ami" "eks-worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${aws_eks_cluster.eks.version}-v*"]
  }
  most_recent = true
  owners      = ["602401143452"] # Amazon EKS AMI Account ID
}
data "aws_region" "current" {}

locals {
  eks-node-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.eks.endpoint}' --b64-cluster-ca '${aws_eks_cluster.eks.certificate_authority.0.data}' '${var.cluster-name}'
USERDATA
}

resource "aws_launch_configuration" "eks" {
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.eks-node.name}"
  image_id                    = "${data.aws_ami.eks-worker.id}"
  instance_type               = "m4.large"
  name_prefix                 = "terraform-eks-demo"
  security_groups             = ["${aws_security_group.eks-node.id}"]
  user_data_base64            = "${base64encode(local.eks-node-userdata)}"
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_autoscaling_group" "eks" {
  desired_capacity     = 2
  launch_configuration = "${aws_launch_configuration.eks.id}"
  max_size             = 2
  min_size             = 1
  name                 = "aws-eks-terraform"
  vpc_zone_identifier  = ["${aws_subnet.eks_subnet.*.id}"]
  tag {
    key                 = "Name"
    value               = "aws-eks-terraform"
    propagate_at_launch = true
  }
  tag {
    key                 = "kubernetes.io/cluster/${var.cluster-name}"
    value               = "owned"
    propagate_at_launch = true
  }
}
