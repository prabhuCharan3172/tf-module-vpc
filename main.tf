resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
  tags = {
    Name = "${var.env}-vpc"
  }
}
module "subnets" {
  for_each = var.subnets
  source = "./subnets"
  subnets =each.value["subnet_cidr"]
  name = each.value["name"]
  vpc_id =aws_vpc.main.id
  AZ = var.AZ
}