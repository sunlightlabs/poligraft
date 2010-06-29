require File.expand_path('../boot', __FILE__)

require "action_controller/railtie"
require "action_mailer/railtie"
require "rails/test_unit/railtie"

Bundler.require(:default, Rails.env) if defined?(Bundler)
MongoMapper.database = "poligraft-#{Rails.env}"

module Poligraft
  class Application < Rails::Application
    config.time_zone = 'Eastern Time (US & Canada)'
    config.encoding = "utf-8"
    config.filter_parameters += [:password]
  end
end
