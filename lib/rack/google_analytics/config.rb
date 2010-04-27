require 'delegate'
module Rack
  module GoogleAnalytics
    class Config < DelegateClass(Hash)      
      attr_reader :cookie_name, :cookie_persistence, :transparent_image_body, :web_property_id, :utm_gif_location, :utm_version
      def initialize(hash = {})
        hash = hash.dup
        {
          :utm_version => '4.4sp',
          :utm_gif_location => "http://www.google-analytics.com/__utm.gif",
          :cookie_persistence => 63072000,
          :cookie_name => '__utmmobile',
          :transparent_image_body => "GIF89a\001\000\001\000\200\000\000\377\377\377\000\000\000!\371\004\001\000\000\000\000,\000\000\000\000\001\000\001\000\000\002\002D\001\000;"
        }.each do |key, value|
          instance_variable_set("@#{key}",hash.delete(key) || value)
        end
        @web_property_id = hash.delete(:web_property_id)
        super(hash)
      end

      def google_analytics_image_path?(path)
        self[:google_analytics_image_path] && path =~ /^#{Regexp.escape(self[:google_analytics_image_path])}/
      end

      def random_integer
        rand(0x7fffffff)
      end
      
      # Returns JS to be embeded. This takes one argument, a Web Property ID
      # (aka UA number).
      def tracking_code
        returning_value = <<-EOF
        <script type="text/javascript">
        if (typeof gaJsHost == 'undefined') {
          var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
          document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));
        }
        </script>
        <script type="text/javascript">
        try {
          var #{self[:prefix]}pageTracker = _gat._getTracker("#{web_property_id}");
          EOF
          if self[:multiple_top_level_domains]
            returning_value << <<-EOF
            #{self[:prefix]}pageTracker._setDomainName("none");
            #{self[:prefix]}pageTracker._setAllowLinker(true);
            EOF
          elsif self[:domain_name]
            returning_value << <<-EOF
            #{self[:prefix]}pageTracker._setDomainName("#{self[:domain_name]}");
            EOF
          end
          returning_value << <<-EOF
          #{self[:prefix]}pageTracker._trackPageview();
        } catch(err) {}</script>
        EOF
        returning_value
      end
    end
  end
end
