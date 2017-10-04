Aws::CF::Signer.configure do |config|
  # mangle our env var to get it into expected key syntax
  priv_key = ENV['CLOUDFRONT_KEY'].gsub('"', '').gsub(/\\n/, "\n")
  config.key          = priv_key
  config.key_pair_id  = ENV['CLOUDFRONT_KEY_PAIR_ID']
  config.default_expires = 3600 # 1hr as seconds
end

# monkey patches via 
# http://stackoverflow.com/questions/9956712/use-cdn-with-carrierwave-fog-in-s3-cloudfront-with-rails-3-1
module CarrierWave
  module Uploader
    module Url
      extend ActiveSupport::Concern
      include CarrierWave::Uploader::Configuration
      include CarrierWave::Utilities::Uri

      ##
      # === Parameters
      #
      # [Hash] optional, the query params (only AWS)
      #
      # === Returns
      #
      # [String] the location where this file is accessible via a url
      #
      def signed_url(options = {})
        #STDERR.puts "file.signed_url options=#{options.inspect}"
        u = url(options)
        Aws::CF::Signer.sign_url(u)
      end
    end # Url
  end # Uploader
end # CarrierWave

require "fog"

module CarrierWave
  module Storage
    class Fog < Abstract
       class File
          include CarrierWave::Utilities::Uri
          def url
             # Delete 'if statement' related to fog_public
             public_url
          end

          # provider setter for CopyToS3Task temp assignment
          def path=(p)
            @path = p
          end
       end
    end
  end
end
