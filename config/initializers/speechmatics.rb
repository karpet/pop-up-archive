Speechmatics.configure do |sm|
  sm.auth_token = ENV['SPEECHMATICS_AUTH_TOKEN']
  sm.user_id    = ENV['SPEECHMATICS_USER_ID']
end