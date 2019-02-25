variable base_tags {
  description = "Tag に設定するデフォルト値"
  type        = "map"
}

variable api_name {
  default = "stns-api"
}

variable api_key {}

variable stage_name {
  default = "v2"
}

variable api_policy_json {
  default = ""
}

variable api_policy_file {
  default = ""
}

variable user_table_name {
  default = "stns-users"
}

variable group_table_name {
  default = "stns-groups"
}

variable auth_table_name {
  default = "stns-authorizations"
}

variable log_retention_in_days {
  default = 30
}
