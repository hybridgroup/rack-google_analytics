require 'test_helper'
require 'rack/mock'
require 'test/unit'
class Curl::Easy
  class << self
    attr_reader :method_call_registry
    def clear_method_call_registry
      @method_call_registry = nil
    end
    def perform(*args, &block)
      @method_call_registry ||= {}
      @method_call_registry[:perform] ||= []
      @method_call_registry[:perform] << [args, block].flatten
    end
  end
end
class Rack::GoogleAnalyticsTest < Test::Unit::TestCase
  def test_image_path_returns_transparent_image
    Curl::Easy.clear_method_call_registry
    
    request(:path => default_config.utm_image_path, :track_via_utm_image => true) do |app, req|
      assert_equal app.config.utm_image_body, req.body
      assert_equal 'image/gif', req.headers['Content-Type']
    end
    
    assert_match /^#{Regexp.escape(default_config.utm_image_google_image_url)}\?/, Curl::Easy.method_call_registry[:perform].last[0]
    assert_respond_to Curl::Easy.method_call_registry[:perform].last[1], :call
  end

  def test_utm_image_path_not_used_if_request
    request(:path => '/hello', :utm_image_path => '/ga.gif') do |app, req|
      assert_equal 'text/html', req.headers['Content-Type']
      assert_not_equal app.config.utm_image_body, req.body
    end
  end

  def test_embed_tracking_code_at_the_end_of_html_body
    assert_match TRACKER_EXPECT, request.body
  end

  def test_embed_tracking_code_in_xhtml_documents
    assert_match TRACKER_EXPECT, request(:content_type => "application/xhtml+xml").body
  end

  def test_dont_embed_code_in_non_html_documents
    assert_no_match TRACKER_EXPECT, request(:content_type => "text/xml", :body => [XML_DOC]).body 
  end

  def test_should_not_raise_exception_if_theres_no_html_body_tag
    assert_nothing_raised { request(:body => ["<html></html>"]) }
  end

  def test_shoud_buff_content_length_by_the_size_of_tracker_code
    request do |app, req|
      assert_equal HTML_DOC.length + app.config.tracking_code.length, req.content_length
    end
  end
  
  def test_shoud_include_pageTracker_definition
    assert_match( /#{Regexp.escape('var pageTracker = _gat.')}/, request.body)
  end
  
  def test_shoud_append_prefix_to_pageTracker_definition
    assert_match( /#{Regexp.escape('var conductor_pageTracker = _gat.')}/, request(:prefix => 'conductor_').body)
  end

  def test_shoud_allow_multiple_top_level_domains
    assert_match( /#{Regexp.escape('pageTracker._setDomainName("none")')}/, request(:multiple_top_level_domains => true).body)
    assert_match( /#{Regexp.escape('pageTracker._setAllowLinker(true)')}/, request(:multiple_top_level_domains => true).body)
  end

  def test_multiple_top_level_domains_should_supercede_domain_name
    request(:multiple_top_level_domains => true, :domain_name => '.test.com') do |app, req|
      assert_match( /#{Regexp.escape('pageTracker._setDomainName("none")')}/, req.body)
      assert_no_match( /#{Regexp.escape('pageTracker._setDomainName(".test.com")')}/, req.body)
    end
  end

  def test_shoud_allow_domain_name
    assert_match( /#{Regexp.escape('pageTracker._setDomainName(".test.com")')}/, request(:domain_name => '.test.com').body)
  end
  

  private
    WEB_PROPERTY_ID = "UA-0000000-1"

    TRACKER_EXPECT = /<script.*pageTracker.*<\/script>\s?<\/body>/m

    HTML_DOC = <<-EOF
    <html>
      <head>
        <title>Rack::GoogleAnalytics</title>
      </head>
      <body>
        <h1>Rack::GoogleAnalytics</h1>
      </body>
    </html>
    EOF

    XML_DOC = <<-EOF
    <?xml version="1.0" encoding="ISO-8859-1"?>
    <poem>
      <title>Old Pond</title>
      <author>Matsuo Basho</author>
      <body>an ancient pond / a frog jumps in / the splash of water</body>
    </poem>
    EOF

    def request(opts = {})
      opts = opts.clone
      path = opts.delete(:path) || '/'
      @application = app(opts)
      @request = Rack::MockRequest.new(@application).get(path)
      yield(@application, @request) if block_given?
      @request
    end

    def app(opts = {})
      opts = opts.clone
      opts[:content_type] ||= "text/html"
      opts[:body]         ||= [HTML_DOC]
      rack_app = lambda { |env| [200, { 'Content-Type' => opts.delete(:content_type) }, opts.delete(:body)] }
      opts[:web_property_id] ||= WEB_PROPERTY_ID
      Rack::GoogleAnalytics.new(rack_app, opts)
    end

    def default_config
      @default_config ||= Rack::GoogleAnalytics::Config.new(:web_property_id => WEB_PROPERTY_ID)
    end
end
