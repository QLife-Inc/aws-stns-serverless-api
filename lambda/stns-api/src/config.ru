require 'rack'
require 'rack/contrib'
require_relative 'server'

set :root, __dir__

run Sinatra::Application
