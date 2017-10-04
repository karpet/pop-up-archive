CarrierWave.configure do |config|

  config.remove_previously_stored_files_after_update = false

  config.root = Rails.root.join('tmp')
  config.cache_dir = "#{Rails.root}/tmp/uploads"

  config.storage        = :fog

  config.asset_host     = proc do |file|
    #pp file
    #STDERR.puts "file provider==#{file.model.storage.provider}"
    #STDERR.puts caller.join("\n")
    host = nil
    if Rails.env.test?
      # TODO a way to test Carrierwave+Fog with better mock
 
    elsif file.model.storage.at_internet_archive?
      # TODO optional IA CDN?
 
    elsif ENV['CDN']
      host = ENV['CDN']
    end
    host
  end

  config.fog_directory  = ENV['AWS_BUCKET']
  config.fog_public     = false

  config.fog_credentials = {
    provider:              'AWS',
    aws_access_key_id:     ENV['AWS_ACCESS_KEY_ID'],
    aws_secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
  }

  config.fog_attributes = {}

  if Rails.env.test? or Rails.env.cucumber?
    config.storage = :file
    config.enable_processing = false
  end
end
