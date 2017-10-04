require 'spec_helper'
describe Api::V1::OrganizationsController do
  extend ControllerMacros

  before { StripeMock.start }
  after { StripeMock.stop }

  login_user

  before :each do
    request.accept = "application/json"
  end

  describe "CRUD" do

    before :each do
      @org = FactoryGirl.create :organization
      @logged_in_user.add_to_team(@org)
    end

    it 'show' do
      get 'show', id: @org.id
      response.should be_success
    end

    it 'member' do
      user = FactoryGirl.create :user
      post 'member', id: @org.id, email: user.email
      response.should be_success
      r = JSON.parse(response.body)
      r['msg'].should eq 'invite sent'
    end

  end

end

