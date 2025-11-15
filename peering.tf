resource "aws_vpc_peering_connection" "default" {
    count = var.is_peering_required ? 1 : 0
#   peer_owner_id = var.peer_owner_id
  peer_vpc_id   = data.aws_vpc.default.id
  vpc_id        = aws_vpc.main.id

accepter {
    allow_remote_vpc_dns_resolution = true

    
}

requester {
    allow_remote_vpc_dns_resolution = true
}

    auto_accept = true

}

resource "aws_route" "publictodefault" {
    count = var.is_peering_required ? 1 : 0


  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = data.aws_vpc.default.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.default[count.index].id
}

resource "aws_route" "defaulttopublic" {
    count = var.is_peering_required ? 1 : 0


  route_table_id            = data.aws_route_table.default.id
  destination_cidr_block    = var.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.default[count.index].id
}