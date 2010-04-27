require 'rack/google_analytics/config'
require 'rack/google_analytics/dispatcher'
module Rack #:nodoc:
  module GoogleAnalytics
    def self.new(app, options = {})
      @config = Rack::GoogleAnalytics::Config.new(options)
      Rack::GoogleAnalytics::Dispatcher.new(app, @config)
    end
    def self.config
      @config
    end
  end
end