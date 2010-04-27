require "delegate"
require 'digest/md5'
require 'curb'
require 'rack/request'
module Rack #:nodoc:
  module GoogleAnalytics
    class Image < DelegateClass(Rack::Request)
      def self.new(env, config)
        config.utm_image_path?(env['PATH_INFO']) ? super(env, config) : nil
      end
      attr_reader :account
      attr_reader :guid
      attr_reader :user_agent
      attr_reader :cookie
      attr_reader :document_referrer
      attr_reader :document_path
      attr_reader :config
      def initialize(env, config)
        @config = config
        super(Rack::Request.new(env))
        @time_stamp = Time.now
        @account = params['utmac']
        @guid = env['HTTP_X_DCMGUID']
        @user_agent = env['HTTP_USER_AGENT']
        @cookie = cookies[config.utm_image_cookie_name]
        @document_referrer = URI.decode(params['utmr'] || '-')
        @document_path = URI.decode(params['utmr'] || '')
      end

      def to_a
        headers = {
          "Content-Type" => "image/gif",
          "Cache-Control" => 'private, no-cache, no-cache=Set-Cookie, proxy-revalidate',
          "Pragma" => 'no-cache',
          "Expires" => "Wed, 17 Sep 1975 21:32:10 GMT"
        }

        headers['X_GA_MOBILE_URL'] = utm_image_url if debug?
        send_request_to_google_analytics

        Rack::Response.new([body],200,headers.dup) do |response|
          response.set_cookie(config.utm_image_cookie_name, {:value => visitor_id, :expires => (@time_stamp + config.utm_image_cookie_persistence)})
        end.to_a
      end

      protected

      def body
        config.utm_image_body
      end

      def random_integer
        config.random_integer
      end

      def utm_image_url
        @utm_image_url ||= "#{config.utm_image_google_image_url}?" <<
        "utmwv=#{config.utm_image_version}" <<
        "&utmn=#{random_integer}" <<
        "&utmhn=#{URI.encode('map.nd.edu')}" <<
        "&utmr=#{URI.encode(document_referrer)}" <<
        "&utmp=#{URI.encode(document_path)}" <<
        "&utmac=#{account}" <<
        "&utmcc=__utma%3D999.999.999.999.999.1%3B" <<
        "&utmvid=#{visitor_id}" <<
        "&utmip=#{ip}"
      end

      def send_request_to_google_analytics
        Curl::Easy.perform(utm_image_url) do |curl|
          curl.headers['User-Agent'] = user_agent
          curl.headers['Accepts-Language'] = env['HTTP_ACCEPT_LANGUAGE']
          curl.verbose = debug?
        end
      end

      # Capture the first three octects of the IP address and replace the forth
      # with 0, e.g. 124.455.3.123 becomes 124.455.3.0
      def ip
        @ip ||= super.to_s =~ /^((\d{1,3}\.){3})\d{1,3}$/ ? "#{$1}0" : ""
      end

      def debug?
        params.key?('utmdebug')
      end

      def visitor_id
        @visitor_id ||=
        if cookie.nil?
          message = guid.nil? ? "#{user_agent}#{random_integer}" : "#{guid}#{account}"
          "0x#{Digest::MD5.hexdigest(message)[0..16]}"
        else
          cookie
        end
      end
    end
  end
end
