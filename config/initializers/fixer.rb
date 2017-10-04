require 'fixer_client'

Fixer.configure do |c|
  c.client_id     = ENV['FIXER_KEY']
  c.client_secret = ENV['FIXER_SECRET']
  c.endpoint      = ENV['FIXER_ENDPOINT']
end
