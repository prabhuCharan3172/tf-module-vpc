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
  ngw=try(each.value["ngw"], false)
  igw=try(each.value["igw"], false)
  env=var.env
  igw_id=aws_internet_gateway.igw.id
  route_table=aws_route_table.route_table
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.env}-igw"
  }
}
resource "aws_eip" "ngw" {
  vpc = true
}
resource "aws_nat_gateway" "example" {
  allocation_id = aws_eip.ngw.id
  subnet_id     = module.subnets["public"].out[0].id
  tags          = {
    Name = "${var.env}-ngw"
  }
}
resource "aws_route_table" "route_table" {
  for_each = var.subnets
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${each.value["name"]}-rt"
  }
}
resource "aws_route" "public" {
  route_table_id              = aws_route_table.route_table["public"].id
  destination_cidr_block = "0.0.0.0/0"
  carrier_gateway_id = aws_internet_gateway.igw.id
}
resource "aws_route_table_association" "public" {
  count =length(module.subnets["public"].out[*].id)
  subnet_id      = element(module.subnets["public"].out[*].id, count.index)
  route_table_id = aws_route_table.route_table["public"].id
}
output "out" {
  value = module.subnets["public"].out[*].id
}