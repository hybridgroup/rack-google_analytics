require 'rack/google_analytics/body'
require 'rack/google_analytics/image'
module Rack
  module GoogleAnalytics
    # Responsible for rendering:
    # 1) an image for google analytics for mobile 
    #    devices (http://code.google.com/apis/mobileanalytics/docs/web/)
    # 
    # OR 
    # 
    # 2) Appending to the a the response body a google-analytics script
    class Dispatcher
      attr_reader :app, :config
      def initialize(app, config)
        @app, @config = app, config
      end

      def call(env)
        short_circuit_for_image(env) || pass_through_with_response_change(env)
      end
      
      protected

      def short_circuit_for_image(env)
        Image.new(env, config).to_a
      end

      # In this case, we need to call the app to get
      # the returning Content-Type
      def pass_through_with_response_change(env)
        status, headers, response = app.call(env)

        if headers["Content-Type"] =~ /text\/html|application\/xhtml\+xml/
          Body.new(status, headers, response, config).to_a
        else
          [status, headers, response]
        end
      end
    end
  end
end
