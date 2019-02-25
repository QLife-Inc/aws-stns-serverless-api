require 'rack/test'
require 'simplecov'
require 'simplecov-console'

FORMATTERS = [
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::Console,
]

SimpleCov.start do
  add_filter '/vendor/'
  add_filter '/spec/'
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(FORMATTERS)
end

ENV['RACK_ENV'] = 'test'

require_relative '../src/server'

module RSpecMixin
  include Rack::Test::Methods
  def app() Sinatra::Application end
end

RSpec.configure do |config|
  config.include RSpecMixin
end
