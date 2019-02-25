# https://github.com/aws-samples/serverless-sinatra-sample/blob/master/app/server.rb
require 'sinatra'
require 'aws-record'
require 'logger'
require_relative 'models/authorization_context'
require_relative 'services/user_service'
require_relative 'services/group_service'

logger = Logger.new(STDOUT)

before do
  content_type :json
  # ↓↓↓ ここからサンプルコードまま ↓↓↓
  if request.body.size > 0
    request.body.rewind
    @params ||= Sinatra::IndifferentHash.new
    @params.merge!(JSON.parse(request.body.read))
  end
  # ↑↑↑ ここまでサンプルコードまま ↑↑↑
  authz_context = JSON.parse(ENV['AUTHORIZATION_CONTEXT'] || '{}')
  @authz_context = AuthorizationContext.new(authz_context)
  logger.debug(@authz_context.to_h.to_json)
end

get '/users' do
  logger.debug("params = #{params}")
  users = UserService.get_users(params, @authz_context)
  logger.debug(users.to_json)
  users.to_json
end

get '/groups' do
  logger.debug("params = #{params}")
  groups = GroupService.get_groups(params, @authz_context)
  logger.debug(groups.to_json)
  groups.to_json
end
