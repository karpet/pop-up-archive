# encoding: utf-8

class CsvFileUploader < CarrierWave::Uploader::Base
  include Sprockets::Rails::Helper

  def extension_white_list
    ['csv']
  end
end
