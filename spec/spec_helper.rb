ENV["RAILS_ENV"] ||= 'test'

require File.dirname(__FILE__) + "/../config/environment" unless defined?(Rails)
require 'rspec/rails'
require 'steak'
require 'capybara/rails'
require 'capybara/rspec'
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.include Capybara::DSL
  config.mock_with :rr
  # config.use_transactional_examples = false #? not using ActiveRecord
end

Capybara.configure do |config|
  config.default_selector = :css
end