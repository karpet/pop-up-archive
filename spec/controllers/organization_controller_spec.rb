require 'spec_helper'
describe OrganizationController do
  extend ControllerMacros

  before { StripeMock.start }
  after { StripeMock.stop }

  it "should confirm member invite" do
    user = FactoryGirl.create :user
    org = FactoryGirl.create :organization
    org.invite_user(user)
    user.reload # get token
    get 'confirm_invite', org_id: org.id, invitation_token: user.invitation_token
    response.should be_redirect
    response.location.should match('/account')
  end

end
