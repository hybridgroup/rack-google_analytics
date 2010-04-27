module Rack
  module GoogleAnalytics
    class Body
      attr_reader :status, :headers, :response, :config
      def initialize(status, headers, response, config)
        @status, @headers, @response, @config = status, headers, response, config
        body = ""
        response.each { |part| body << part }
        index = body.rindex("</body>")
        if index
          body.insert(index, config.tracking_code)
          headers["Content-Length"] = body.length.to_s
          @response = [body]
        end
      end

      def to_a
        [status, headers, response]
      end
    end
  end
end
