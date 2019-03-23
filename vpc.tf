data "aws_availability_zones" "available" {}
resource "aws_vpc" "eks_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = "${
    map(
     "Name", "aws-eks-terraform-node",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}
resource "aws_subnet" "eks_subnet" {
  count = 2
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block        = "10.0.${count.index}.0/24"
  vpc_id            = "${aws_vpc.eks_vpc.id}"
  tags = "${
    map(
     "Name", "aws-eks-terraform-node",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}
resource "aws_internet_gateway" "eks_nat" {
  vpc_id = "${aws_vpc.eks_vpc.id}"
  tags = {
    Name = "aws-eks-terraform"
  }
}
resource "aws_route_table" "eks_route" {
  vpc_id = "${aws_vpc.eks_vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.eks_nat.id}"
  }
}
resource "aws_route_table_association" "eks_route_association" {
  count = 2
  subnet_id      = "${aws_subnet.eks_subnet.*.id[count.index]}"
  route_table_id = "${aws_route_table.eks_route.id}"
}
