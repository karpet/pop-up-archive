class OrganizationController < ApplicationController

  # GET to /organziation/:id/:invitation_token
  # will confirm the invitation and redirect to /account page
  def confirm_invite
    token = params[:invitation_token]
    org_id = params[:org_id]
    org = Organization.find org_id.to_i
    user = User.find_by_invitation_token(token)
    if !org or !user
      self.not_found and return
    end

    if user.confirm_org_member_invite(org)
      redirect_to root_url + 'account'
    else
      # error cases
      # (a) token already redeemed
      # (b) something wrong with user.add_to_team
      # (c) invite id mismatch
      # (d) ???
      flash[:alert] = "Organization membership confirmation failed."
      redirect_to root_url
    end
  end

end
