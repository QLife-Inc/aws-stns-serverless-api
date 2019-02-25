require 'json'
require 'aws-sdk'
require 'aws-record'
require 'logger'

ACCOUNT_ID = Aws::STS::Client.new(region: ENV['AWS_REGION']).get_caller_identity().account
API_ID = ENV['API_ID']
RESOURCE_PREFIX = "arn:aws:execute-api:#{ENV['AWS_REGION']}:#{ACCOUNT_ID}:#{API_ID}/*"
READONLY_RESOURCE = "#{RESOURCE_PREFIX}/GET/*"
ALL_RESOURCE = "#{RESOURCE_PREFIX}/*"

LOG = Logger.new(STDOUT)

class Authorization
  include Aws::Record
  set_table_name ENV['AUTH_TABLE']
  string_attr :token, hash_key: true
  list_attr :users
  list_attr :groups
  boolean_attr :is_admin

  def admin?
    self.is_admin
  end
end

def lambda_handler(event:, context:)
  token = extract_token(event)
  authz_context = find_authorization_context(token)
  create_response(token, authz_context)
end

def create_response(token, authz_context)
  response = {
    principalId: token,
    policyDocument: {
      Version: '2012-10-17',
      Statement: [ create_statement(authz_context) ]
    },
    usageIdentifierKey: ENV['API_KEY']
  }
  response[:context] = authz_context.to_h unless authz_context
  response
end

def create_statement(authz_context)
  if authz_context.nil?
    LOG.debug("AuthorizationContext is not found !!")
    create_failure_statement()
  else
    LOG.debug("AuthorizationContext = #{authz_context.to_h.to_json}")
    create_success_statement(authz_context.admin?)
  end
end

def create_success_statement(is_admin)
  resource = is_admin ? ALL_RESOURCE : READONLY_RESOURCE
  { Action: 'execute-api:Invoke', Effect: 'Allow', Resource: resource }
end

def create_failure_statement()
  { Action: 'execute-api:Invoke', Effect: 'Deny', Resource: ALL_RESOURCE }
end

def extract_token(event)
  LOG.debug("API Event = #{event.to_json}")
  event.dig('authorizationToken')&.sub(/^token /, '')
end

def find_authorization_context(token)
  LOG.debug("AuthorizationToken = '#{token}'")
  Authorization.find(token: token)
end
