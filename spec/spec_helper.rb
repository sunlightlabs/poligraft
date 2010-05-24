ENV["RAILS_ENV"] ||= 'test'

require File.dirname(__FILE__) + "/../config/environment" unless defined?(Rails)
require 'rspec/rails'
require "steak"
require 'capybara/rails'
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

Rspec.configure do |config|
  config.include Capybara
  config.mock_with :rr
  # config.use_transactional_examples = false
end

Capybara.default_selector = :css