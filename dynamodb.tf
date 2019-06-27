resource "aws_dynamodb_table" "stns_users" {
  name           = var.user_table_name
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "name"
  tags           = var.base_tags

  attribute {
    name = "name"
    type = "S"
  }

  attribute {
    name = "id"
    type = "S"
  }

  global_secondary_index {
    name            = "id_index"
    hash_key        = "id"
    projection_type = "ALL"
    read_capacity   = 1
    write_capacity  = 1
  }
}

resource "aws_dynamodb_table" "stns_groups" {
  name           = var.group_table_name
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "name"
  tags           = var.base_tags

  attribute {
    name = "name"
    type = "S"
  }

  attribute {
    name = "id"
    type = "S"
  }

  global_secondary_index {
    name            = "id_index"
    hash_key        = "id"
    projection_type = "ALL"
    read_capacity   = 1
    write_capacity  = 1
  }
}

resource "aws_dynamodb_table" "stns_auth" {
  name           = var.auth_table_name
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "token"
  tags           = var.base_tags

  attribute {
    name = "token"
    type = "S"
  }
}

