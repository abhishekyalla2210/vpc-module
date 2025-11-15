    # creating the vpc
    resource "aws_vpc" "main" {
      cidr_block = var.cidr_block
      instance_tenancy = "default"
      enable_dns_hostnames = true
      tags = merge(
        var.vpc_tags,
        local.common_tags,
        {
          Name = local.common_name
        }
      )
    }
# creating the internet gateway
    resource "aws_internet_gateway" "main" {
      vpc_id = aws_vpc.main.id

      tags = merge(
        var.agw,
        local.common_tags,
        {
          Name = "${local.common_name}-new"
        }
      )
    }

    
    # creating the  public subnet

    resource "aws_subnet" "public_subnet" {
      count = length(var.public_subnet_cidr)
      vpc_id            = aws_vpc.main.id
      cidr_block        = var.public_subnet_cidr[count.index]
      availability_zone = local.az-names[count.index] # Replace with your desired AZ
      map_public_ip_on_launch = true
      tags = merge(
        var.public_subnet_tags,
        local.common_tags,
        {
          Name = "${local.common_name}-public-${local.az-names[count.index]}"
        }
      )
    }

    # creating the  private subnet

    resource "aws_subnet" "private_subnet" {
      count = length(var.private_subnet_cidr)
      vpc_id            = aws_vpc.main.id
      cidr_block        = var.private_subnet_cidr[count.index]
      availability_zone = local.az-names[count.index] # Replace with your desired AZ
    
      tags = merge(
        var.public_subnet_tags,
        local.common_tags,
        {
          Name = "${local.common_name}-private-${local.az-names[count.index]}"
        }
      )
    }

    # creating the  database subnet

    resource "aws_subnet" "database_subnet" {
      count = length(var.database_subnet_cidr)
      vpc_id            = aws_vpc.main.id
      cidr_block        = var.database_subnet_cidr[count.index]
      availability_zone = local.az-names[count.index] # Replace with your desired AZ
    
      tags = merge(
        var.database_subnet_tags,
        local.common_tags,
        {
          Name = "${local.common_name}-database-${local.az-names[count.index]}"
        }
      )
    }

# creating the  public route table

    resource "aws_route_table" "public" {
      vpc_id = aws_vpc.main.id

      tags = merge(
        var.public_route_table_tags,
        local.common_tags,
        {
          Name = "${local.common_name}-public"
        }
      )
    }

    
# creating the  private table

    resource "aws_route_table" "private" {
      vpc_id = aws_vpc.main.id

      tags = merge(
        var.private_route_table_tags,
        local.common_tags,
        {
          Name = "${local.common_name}-private"
        }
      )
    }

    # creating the  database table

    resource "aws_route_table" "database" {
      vpc_id = aws_vpc.main.id

      tags = merge(
        var.database_route_table_tags,
        local.common_tags,
        {
          Name = "${local.common_name}-database"
        }
      )
    }

# giving internet gate to public route table
    resource "aws_route" "public" {
      route_table_id            = aws_route_table.public.id
      destination_cidr_block    = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.main.id
}

# creating the elastic ip 
    resource "aws_eip" "nat" {
      domain   = "vpc"
        tags = merge(
              var.elastic_tags,
              local.common_tags,
              {
                Name = "${local.common_name}-nat"
              }
            )
}
# creating the nat gateway 

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnet[0].id

  tags = {
    Name = "gw NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.main]
}


#attaching nat gateway to private route table

resource "aws_route" "private" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id =  aws_nat_gateway.nat.id
}

#attaching nat gateway to database route table

resource "aws_route" "database" {
  route_table_id            = aws_route_table.database.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id =  aws_nat_gateway.nat.id
}

#attaching routes from public route table to public subnets
resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidr)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public.id
}


#attaching routes from private route table to private subnets

resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidr)
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private.id
}

#attaching routes from database route table to database subnets

resource "aws_route_table_association" "database" {
  count = length(var.database_subnet_cidr)
  subnet_id      = aws_subnet.database_subnet[count.index].id
  route_table_id = aws_route_table.database.id
}





    

        


        

