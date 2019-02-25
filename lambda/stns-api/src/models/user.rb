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
  list_attr :link_users
  global_secondary_index :id_index,
                         hash_key: :id,
                         projection: { projection_type: 'ALL' }

  # null があるとセグフォになるので、空文字に変換
  def to_h
    {
        name: name,
        id: id.to_i,
        password: password || '',
        directory: directory || "/home/#{name}",
        shell: shell || '/bin/bash',
        gecos: gecos || '',
        keys: keys_with_link_users,
        group_id: group_id&.to_i || ''
    }
  end

  private

  def keys_with_link_users
    @keys_with_link_users ||= ((keys || []) + link_user_keys).uniq
  end

  def link_user_keys
    return [] unless has_link_user?
    link_users.flat_map { |name| User.find(name: name)&.keys }.compact
  end

  def has_link_user?
    !link_users.nil? && !link_users.empty?
  end
end
