# encoding: utf-8
class MailchimpWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'google_analytics', retry: 10

  # :nocov:
  def perform(list_id, user_email, segment_id=nil)
    begin
      mailchimp = Mailchimp::API.new(ENV['MAILCHIMP_API_KEY'])
      mailchimp.lists.subscribe(list_id, {"email"=> user_email, "status"=>"pending"})
      if segment_id
        mailchimp.lists.static_segment_members_add(list_id, segment_id, [{email: user_email}])
      end
    rescue => e
      raise e
    end
    true
  end
  # :nocov:
end
