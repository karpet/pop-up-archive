require 'spec_helper'
describe Api::V1::ItemsController do
  extend ControllerMacros

  before { StripeMock.start }
  after { StripeMock.stop }

  login_user

  before :each do
    request.accept = "application/json"
  end

  describe "create" do

    it 'create' do
      post 'create', :collection_id => @logged_in_user.collections.first.id, :title => 'test item'
      #STDERR.puts response.body
      response.should be_success
    end

  end

  describe "show and update existing" do

    before :each do
      @item = FactoryGirl.create :item
      @logged_in_user.collections << @item.collection
    end

    it 'show' do
      get 'show', :id => @item.id, :collection_id => @item.collection_id
      response.should be_success
    end

    it 'update' do
      put 'update', :id => @item.id, :collection_id => @item.collection_id, :title => 'new title'
      #STDERR.puts response.body
      response.should be_success
    end

    it 'destroy' do
      delete 'destroy', :id => @item.id, :collection_id => @item.collection_id
      #STDERR.puts response.body
      response.should be_success
    end
    
  end

end

