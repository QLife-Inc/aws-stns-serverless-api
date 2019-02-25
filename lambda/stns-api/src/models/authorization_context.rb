class AuthorizationContext
  attr_reader :principalId

  # @param [Hash] authorizer
  def initialize(authorizer)
    @principalId = authorizer['principalId']
    @users = authorizer['users'] || []
    @groups = authorizer['groups'] || []
    @is_admin = authorizer['is_admin'] === 'true'
  end

  # @param [Array<User>] users
  def filter_users(users)
    return [] if users.nil? || users.empty?
    return users unless needs_user_filtering?
    users.select { |user| @users.include?(user.name) }
  end

  # @param [Array<Group>] groups
  def filter_groups(groups)
    return [] if groups.nil? || groups.empty?
    return groups unless needs_group_filtering?
    groups.select { |group| @groups.include?(group.name) }
  end

  def to_h
    {
        principalId: @principalId,
        users: @users,
        groups: @groups,
        is_admin: admin?,
        enable_user_filtering: needs_user_filtering?,
        enable_group_filtering: needs_group_filtering?
    }
  end

  def to_s
    to_h.to_json
  end

  private

  # @return bool
  def admin?
    @is_admin
  end

  def needs_user_filtering?
    !admin? && !@users.empty?
  end

  def needs_group_filtering?
    !admin? && !@groups.empty?
  end
end
