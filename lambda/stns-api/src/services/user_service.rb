require_relative '../models/user'

class UserService
  class << self
    # @param [Hash] params
    # @param [AuthorizationContext] authz
    def get_users(params, authz)
      users = case true
              when params.key?('name')
                user = find_by_name(params['name'])
                user.nil? ? [] : [ user ]
              when params.key?('id')
                user = find_by_id(params['id'])
                user.nil? ? [] : [ user ]
              else
                User.scan
              end
      authz.filter_users(users).map(&:to_h)
    end

    private

    def find_by_name(name)
      User.find(name: name)
    end

    def find_by_id(id)
      User.query(index_name: 'id_index',
                 select: 'ALL_ATTRIBUTES',
                 key_condition_expression: 'id = :id',
                 expression_attribute_values: { ':id' => id },
                 limit: 1)&.first
    end
  end
end
