require 'spec_helper'

describe AudioFileUploader do
  before { StripeMock.start }
  after { StripeMock.stop }

  context "handle different providers" do

    let (:collection) { FactoryGirl.build :collection_private }
    let (:item) { FactoryGirl.build :item, collection: collection }
    let (:audio_file) { FactoryGirl.build :audio_file, item: item }
    let (:uploader) { AudioFileUploader.new(audio_file) }
    let (:subject) { uploader }

    let(:weird_config) { StorageConfiguration.new(provider: 'InternetArchive', key: 'k', secret: 's') }

    it "handles no item storage" do
      expect(uploader.fog_credentials).to eq collection.default_storage.credentials
    end
    
    it "handles item storage" do
      item.storage_configuration = weird_config
      expect(uploader.fog_credentials).to eq weird_config.credentials
      uploader.fog_attributes.should have_key(:collections)
      uploader.fog_directory.should eq audio_file.destination_directory
      uploader.fog_public.should eq audio_file.storage.is_public?
      uploader.store_dir.should eq audio_file.store_dir
    end

  end
end
