# require 'acts_as_ferret'
require 'sanitize'
require 'yaml'

# ENV['RAILS_ENV'] ||= 'production'
RAILS_GEM_VERSION = '2.1.2' unless defined? RAILS_GEM_VERSION
require File.join(File.dirname(__FILE__), 'boot')

# imagemagick - not used anymore - may remove
# IMAGE_MAGICK_PATH = "/usr/local/bin/"

# settings we don't want to put into git
SETTINGS = YAML::load(File.open("config/settings.yml"))
SETTINGS.each do |k,v|
  sym = k.respond_to?(:to_sym) ? k.to_sym : k
  SETTINGS[sym] = v
  SETTINGS.delete(k) unless k == sym
end

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use. To use Rails without a database
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Specify gems that this application depends on. 
  # They can then be installed with "rake gems:install" on new installations.
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "aws-s3", :lib => "aws/s3"
  config.gem "authlogic"

  # Only load the plugins named here, in the order given. By default, all plugins 
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]
  #config.plugin_paths += ["#{RAILS_ROOT}/../../Libs"]
  #config.plugins = [:authlogic]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  config.log_level = :info

  # Make Time.zone default to the specified zone, and make Active Record store time values
  # in the database in UTC, and return them converted to the specified local zone.
  # Run "rake -D time" for a list of tasks for finding time zone names. Comment line to use default local time.
  config.time_zone = 'UTC'

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random, 
  # no regular words or you'll be exposed to dictionary attacks.
  #config.action_controller.session = {
  #  :session_key => '_authgasm_example_session',
  #  :secret      => '94b9c594695e69bdef6b1d4be037af5853be976b39a52a02f260fca0d0a36a8f913572bfdb631f55971a3b10b8dd9a875f9776ca61371741544e6ccc064dd41e'
  #}

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with "rake db:sessions:create")
  config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # configure Active Mailer
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    :address => "mail.voiceboxpdx.com",
    :port => "26",
    :domain => "makerlab.com",
    :authentication => :login,
    :user_name => "karaokathon+voiceboxpdx.com",
    :password => "8675309jenny"
  }
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default_charset = "utf-8"

  config.after_initialize do
    # actually we'll use the production mode
    # http://www.codyfauser.com/2008/1/17/paypal-express-payments-with-activemerchant
    # http://www.fortytwo.gr/blog/14/Using-Paypal-with-Rails
    # ActiveMerchant::Billing::Base.mode = :test
    # ActiveMerchant::Billing::Base.gateway_mode = :test
    # ActiveMerchant::Billing::Base.integration_mode = :test
    # ActiveMerchant::Billing::PaypalGateway.pem_file =
    #         File.read(File.dirname(__FILE__) + '/../paypal/paypal_cert.pem')
  end

end
