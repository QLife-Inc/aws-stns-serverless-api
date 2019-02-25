require_relative '../models/group'

class GroupService
  class << self
    # @param [Hash] params
    # @param [AuthorizationContext] authz
    def get_groups(params, authz)
      groups = case true
              when params.key?('name')
                group = find_by_name(params['name'])
                group.nil? ? [] : [ group ]
              when params.key?('id')
                group = find_by_id(params['id'])
                group.nil? ? [] : [ group ]
              else
                Group.scan
              end
      authz.filter_groups(groups).map(&:to_h)
    end

    private

    # @return Group
    def find_by_name(name)
      Group.find(name: name)
    end

    # @return Group
    def find_by_id(id)
      Group.query(index_name: 'id_index',
                  select: 'ALL_ATTRIBUTES',
                  key_condition_expression: 'id = :id',
                  expression_attribute_values: { ':id' => id },
                  limit: 1)&.first
    end
  end
end
