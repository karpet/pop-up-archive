require File.expand_path('../boot', __FILE__)

# Pick the frameworks you want:
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
#require "active_resource/railtie"
require "sprockets/railtie"
require 'elasticsearch/rails/instrumentation'
# require "rails/test_unit/railtie"

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups)
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module PopUpArchive
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W(
      #{config.root}/lib
      #{config.root}/app/models/concerns/
    )

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.action_dispatch.default_headers = {
      'X-Frame-Options' => 'ALLOWALL'
    }

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql

    # rails 5 behavior
    config.active_record.raise_in_transactional_callbacks = true

    # rails 3 behavior.
    # NOTE this is less secure but would require lots of new controller-level code,
    # and we already use protected_attributes gem at the model level.
    # TODO this will need to change in Rails 5.
    config.action_controller.permit_all_parameters = true

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    # Needed for Heroku
    require Rails.root.join('config', 'initializers', 'elasticsearch')
    config.assets.initialize_on_precompile = true
    config.assets.precompile += %w(*.png *.jpg *.jpeg *.gif)

    config.assets.paths << "#{Rails.root}/app/assets/html"

    config.assets.register_mime_type 'text/html', '.html'

    # How long should Stripe API responses be cached locally
    config.stripe_cache = 5.minutes

    # quiet deprecated warning
    I18n.enforce_available_locales = false
    
    require 'sprockets'
    Sprockets.register_engine '.slim', Slim::Template
    
    # SASS paths
    if ENV['RAILS_GROUPS'] == 'assets' || Rails.env.development?
      config.sass.load_paths << File.expand_path('./lib/assets/stylesheets/')
      config.sass.load_paths << File.expand_path('./vendor/assets/stylesheets/')
    end

    # Devise settings
    config.to_prepare do |config|
      Devise::RegistrationsController.layout('login')
      Devise::SessionsController.layout('login')
      Devise::PasswordsController.layout('login')
    end

    # Doorkeeper settings
    config.to_prepare do |config|
      Doorkeeper::ApplicationController.layout('oauth')
      Doorkeeper::ApplicationsController.layout('oauth')
      Doorkeeper::AuthorizationsController.layout('oauth')
      Doorkeeper::AuthorizedApplicationsController.layout('oauth')
    end

    # SMTP (mail) settings
    config.action_mailer.raise_delivery_errors = true
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = { 
      :address              => "smtp.mandrillapp.com",
      :port                 => 587,
      :domain               => 'popuparchive.com',
      :user_name            => ENV['EMAIL_USERNAME'],
      :password             => ENV['EMAIL_PASSWORD'],
    }

    config.middleware.use Rack::Cors do
      allow do
        origins '*'
        resource '/api/*', headers: :any, methods: [:get, :post, :put, :delete, :options]
      end
    end
    config.middleware.use Rack::Deflater

  end
end
