class OrganizationMemberInviteMailer < ActionMailer::Base
  default from: ENV['EMAIL_FROM'], template_path: ['base', 'organization_member_invite_mailer']

  def new_invite(org, user)
    @user, @org = user, org
    mail(to: @user.email, subject: org.name + ' membership invitation')
  end

end
