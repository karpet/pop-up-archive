require 'spec_helper'
describe Api::V1::ImageFilesController do
  extend ControllerMacros
  before { StripeMock.start }
  after { StripeMock.stop }

  login_user

  before :each do
    request.accept = "application/json"
  end

  describe "item image CRUD" do

    before :each do
      @image_file = FactoryGirl.create :image_file_item
    end 

    it 'create' do
      post 'create', :item_id => @image_file.imageable.id, :file => 'test_file'
      response.should be_success
    end 

    it 'show' do
      get 'show', :id => @image_file.id, :item_id => @image_file.imageable.id
      response.should be_redirect
    end 

    it 'upload_to' do
      get 'upload_to', :image_file_id => @image_file.id, :item_id => @image_file.imageable.id
      response.should be_success
    end 

    it 'destroy' do
      imgf_path = "api/items/#{@image_file.imageable.id}/image_files/#{@image_file.id}"
      expect(:delete => imgf_path).to route_to(
        :format        => 'json',
        :controller    => 'api/v1/image_files',
        :action        => 'destroy',
        :item_id       => @image_file.imageable.id.to_s,
        :id            => @image_file.id.to_s,
      )   
      delete 'destroy', :id => @image_file.id, :item_id => @image_file.item.id
      #STDERR.puts response.headers.inspect
      response.should be_success
    end 
  end

  describe "collection image CRUD" do

    before :each do
      @image_file = FactoryGirl.create :image_file_collection
    end

    it 'create' do
      post 'create', :collection_id => @image_file.imageable.id, :file => 'test_file'
      response.should be_success
    end

    it 'show' do
      get 'show', :id => @image_file.id, :collection_id => @image_file.imageable.id
      response.should be_redirect
    end 

    it 'upload_to' do
      get 'upload_to', :image_file_id => @image_file.id, :collection_id => @image_file.imageable.id
      response.should be_success
    end 

    it 'destroy' do
      imgf_path = "api/collections/#{@image_file.imageable.id}/image_files/#{@image_file.id}"
      expect(:delete => imgf_path).to route_to(
        :format        => 'json',
        :controller    => 'api/v1/image_files',
        :action        => 'destroy',
        :collection_id => @image_file.imageable.id.to_s,
        :id            => @image_file.id.to_s,
      )   
      delete 'destroy', :id => @image_file.id, :collection_id => @image_file.imageable.id
      response.should be_success
    end

  end

  describe "upload callbacks" do

    before :each do
      @image_file = FactoryGirl.create(:image_file)
    end      
  
      # it 'all_signatures' do
      #   get 'all_signatures', {:id => @image_file.id, :upload_id => @image_file.upload_id}
      #   response.should be_success
      # end
  
      it 'chunk_loaded' do
        get 'chunk_loaded', :image_file_id => @image_file.id, :collection_id => @image_file.imageable.id
      end

      it 'upload_finished' do
        allow_any_instance_of(ImageFile).to receive(:save_thumb_version).and_return(true)
        get 'upload_finished', :image_file_id => @image_file.id, :key => @image_file.file.path, :file => @image_file.file, :collection_id => @image_file.imageable.id
        response.should be_success
      end
    end 

end
