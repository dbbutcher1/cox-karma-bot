# This file is used by Rack-based servers to start the application.

require_relative 'config/environment'
require ::File.expand_path( 'bot/karma_bot' )

Thread.abort_on_exception = true
Thread.new do
  KarmaBot.run
end

run Rails.application
