require 'delegate'
module Rack
  module GoogleAnalytics
    # Required:
    # - :web_property_id 
    #
    # Optional:
    # - :utm_image_path: if set, then the Image module will be used as well 
    #   (see Config#utm_image_path?)
    # 
    class Config
      PROPERTIES = {
        :web_property_id                => nil,  
        :domain_name                    => nil,  
        :multiple_top_level_domains     => nil,  
        :domain_name                    => nil,  
        :prefix                         => nil,  
        :utm_image_path                 => nil,  
        :utm_cookie_name                => '__utmmobile',  
        :utm_cookie_persistence         => 63072000,  
        :utm_body                       => "GIF89a\001\000\001\000\200\000\000\377\377\377\000\000\000!\371\004\001\000\000\000\000,\000\000\000\000\001\000\001\000\000\002\002D\001\000;",  
        :utm_google_image_url           => 'http://www.google-analytics.com/__utm.gif',
        :utm_version                    => '4.4sp',  
      }.freeze
      PROPERTIES.each do |key, value|
        attr_reader key
      end
      def initialize(hash = {})
        hash = hash.dup
        PROPERTIES.each { |key, value| instance_variable_set("@#{key}",hash.delete(key) || value) }
        
        raise RuntimeError, "You need to set Rack::GoogleAnalytics web_property_id" unless web_property_id
      end

      def utm_image_path?(path)
        utm_image_path && path =~ /^#{Regexp.escape(utm_image_path)}/
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
          var #{prefix}pageTracker = _gat._getTracker("#{web_property_id}");
          EOF
          if multiple_top_level_domains
            returning_value << <<-EOF
            #{prefix}pageTracker._setDomainName("none");
            #{prefix}pageTracker._setAllowLinker(true);
            EOF
          elsif domain_name
            returning_value << <<-EOF
            #{prefix}pageTracker._setDomainName("#{domain_name}");
            EOF
          end
          returning_value << <<-EOF
          #{prefix}pageTracker._trackPageview();
        } catch(err) {}</script>
        EOF
        returning_value
      end
    end
  end
end
