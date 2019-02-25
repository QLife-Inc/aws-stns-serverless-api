class User
  include Aws::Record
  # for DynamoDB Local
  if ENV['DYNAMODB_ENDPOINT']
    configure_client endpoint: ENV['DYNAMODB_ENDPOINT']
  end
  set_table_name ENV['USER_TABLE']
  string_attr :name, hash_key: true
  string_attr :id
  string_attr :password
  string_attr :directory
  string_attr :shell
  string_attr :gecos
  string_attr :group_id
  list_attr :keys
  global_secondary_index :id_index,
                         hash_key: :id,
                         projection: { projection_type: 'ALL' }

  def to_h
    {
        name: name,
        id: id.to_i,
        password: password,
        directory: directory || "/home/#{name}",
        shell: shell || '/bin/bash',
        gecos: gecos,
        keys: keys || [],
        group_id: group_id&.to_i || 0
    }
  end
end
