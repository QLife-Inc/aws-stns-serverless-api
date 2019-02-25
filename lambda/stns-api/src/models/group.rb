class Group
  include Aws::Record
  # for DynamoDB Local
  if ENV['DYNAMODB_ENDPOINT']
    configure_client endpoint: ENV['DYNAMODB_ENDPOINT']
  end
  set_table_name ENV['GROUP_TABLE']
  string_attr :name, hash_key: true
  string_attr :id
  list_attr :users
  list_attr :link_groups
  global_secondary_index :id_index,
                         hash_key: :id,
                         projection: { projection_type: 'ALL' }

  def to_h
    {
      name: name,
      id: id.to_i,
      users: users || [],
      link_groups: link_groups || [],
    }
  end
end
