resource "aws_vpc" "vpc_app" {
  cidr_block = var.network_cidr
  tags = merge(
    var.additional-tags,
    {
      Name = "MyVPC"
    },
  )
}

resource "aws_subnet" "public" {
  count                   = 2
  cidr_block              = cidrsubnet(aws_vpc.vpc_app.cidr_block, 3, count.index)
  availability_zone       = data.aws_availability_zones.available_zones.names[count.index]
  vpc_id                  = aws_vpc.vpc_app.id
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private" {
  count             = 2
  cidr_block        = cidrsubnet(aws_vpc.vpc_app.cidr_block, 3, 2 + count.index)
  availability_zone = data.aws_availability_zones.available_zones.names[count.index]
  vpc_id            = aws_vpc.vpc_app.id
}

resource "aws_subnet" "db" {
  count             = 2
  cidr_block        = cidrsubnet(aws_vpc.vpc_app.cidr_block, 3, 4 + count.index)
  availability_zone = data.aws_availability_zones.available_zones.names[count.index]
  vpc_id            = aws_vpc.vpc_app.id
}

resource "aws_internet_gateway" "igateway" {
  vpc_id = aws_vpc.vpc_app.id
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.vpc_app.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igateway.id
}

resource "aws_eip" "gateway" {
  count      = 2
  depends_on = [aws_internet_gateway.igateway]
}

resource "aws_nat_gateway" "ngateway" {
  count         = 2
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  allocation_id = element(aws_eip.gateway.*.id, count.index)
}

resource "aws_route_table" "private" {
  count  = 2
  vpc_id = aws_vpc.vpc_app.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.ngateway.*.id, count.index)
  }
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}