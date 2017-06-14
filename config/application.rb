require_relative 'boot'

require 'rails/all'
require ::File.expand_path( 'bot/karma_bot' )
# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CoxKarmaBot
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.max_karma = 5
    config.top_limit = 20
    config.top_default = 5
    config.leader_default = 10
  end

  SlackRubyBot::Client.logger.level = Logger::DEBUG
end
