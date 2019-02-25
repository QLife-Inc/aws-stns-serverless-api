require 'aws-record'
require_relative '../src/models/user'
require_relative '../src/models/group'

TABLE_OPTS = {
  provisioned_throughput: {
    read_capacity_units: 1,
    write_capacity_units: 1
  },
  global_secondary_index_throughput: {
    id_index: {
      read_capacity_units: 1,
      write_capacity_units: 1
    }
  }
}

[User, Group].each do |table|
  migration = Aws::Record::TableMigration.new(table)
  unless table.table_exists?
    migration = Aws::Record::TableMigration.new(table)
    migration.create!({}.merge(TABLE_OPTS)) # 値が書き換わるためコピーしたハッシュを渡す
    migration.wait_until_available
  end
end
