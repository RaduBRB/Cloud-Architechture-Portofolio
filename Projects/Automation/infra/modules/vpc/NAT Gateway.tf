resource "aws_nat_gateway" "this" {
    allocation_id = aws_eip.nat.id
    subnet_id = aws_subnet.public[0].id
}

resource "aws_eip" "nat" {
    domain = "vpc"
}
