require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"]
  # or in config/master.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Enable serving static files from the `/public` folder for AWS ALB deployment
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?

  # Compress CSS using a preprocessor.
  # config.assets.css_compressor = :sass

  # Enable asset compilation for AWS deployment
  config.assets.compile = ENV['RAILS_SERVE_STATIC_FILES'].present?
  
  # Asset serving configuration
  config.assets.digest = true
  config.serve_static_assets = ENV['RAILS_SERVE_STATIC_FILES'].present?

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # Use S3 for asset serving in production
  if ENV['S3_BUCKET_NAME'].present?
    config.asset_host = "https://#{ENV['S3_BUCKET_NAME']}.s3.#{ENV['AWS_REGION'] || 'ap-southeast-1'}.amazonaws.com"
  end

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for Apache
  # config.action_dispatch.x_sendfile_header = "X-Accel-Redirect" # for NGINX

  # Store uploaded files on Amazon S3 if configured, otherwise local
  if ENV['S3_BUCKET_NAME'].present?
    config.active_storage.service = :amazon
  else
  config.active_storage.service = :local
  end

  # Mount Action Cable outside main process or domain.
  # config.action_cable.mount_path = nil
  # config.action_cable.url = "wss://example.com/cable"
  # config.action_cable.allowed_request_origins = [ "http://example.com", /http:\/\/example.*/ ]

  # AWS ALB handles SSL termination, so don't force SSL in Rails
  config.force_ssl = false

  # Trust proxies from AWS ALB
  config.force_ssl = false
  config.ssl_options = { redirect: { exclude: -> request { request.path =~ /health/ } } }

  # Include generic and useful information about system operation, but avoid logging too much
  # information to avoid inadvertent exposure of personally identifiable information (PII).
  config.log_level = :info

  # Prepend all log lines with the following tags.
  config.log_tags = [ :request_id ]

  # Use Redis for caching if available
  if ENV['REDIS_URL'].present?
    config.cache_store = :redis_cache_store, { url: ENV['REDIS_URL'] }
  else
    config.cache_store = :memory_store
  end

  # Use a real queuing backend for Active Job (and separate queues per environment).
  # config.active_job.queue_adapter     = :resque
  # config.active_job.queue_name_prefix = "app_production"

  config.action_mailer.perform_caching = false

  # Configure mailer for production
  # Use domain from environment or default to ALB DNS
  default_host = ENV['DOMAIN_NAME'] || ENV['ALB_DNS_NAME'] || 'localhost'
  config.action_mailer.default_url_options = { 
    host: default_host, 
    protocol: ENV['FORCE_SSL'] == 'true' ? 'https' : 'http'
  }
  
  # Email configuration with multiple options
  if ENV['SMTP_USERNAME'].present? && ENV['SMTP_PASSWORD'].present?
    # Gmail SMTP configuration
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address: ENV['SMTP_ADDRESS'] || 'smtp.gmail.com',
      port: ENV['SMTP_PORT'] || 587,
      domain: default_host,
      user_name: ENV['SMTP_USERNAME'],
      password: ENV['SMTP_PASSWORD'],
      authentication: 'plain',
      enable_starttls_auto: true,
      open_timeout: 10,
      read_timeout: 10
    }
    puts "✅ SMTP configured for email delivery"
  elsif ENV['AWS_REGION'].present? && ENV['AWS_ACCESS_KEY_ID'].present?
    # AWS SES configuration (if you want to use SES instead)
    config.action_mailer.delivery_method = :aws_ses
    puts "✅ AWS SES configured for email delivery"
  else
    # Fallback to test delivery method (logs emails instead of sending)
    config.action_mailer.delivery_method = :test
    puts "❌ No email credentials found. Emails will not be sent!"
    puts "Please set SMTP_USERNAME and SMTP_PASSWORD environment variables."
  end

  # Enable delivery errors to see what's happening
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_deliveries = true

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Use a different logger for distributed setups.
  # require "syslog/logger"
  # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new "app-name")

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # AWS specific configurations
  if Rails.env.production?
    # Health check endpoint for ALB
    config.middleware.use(Class.new do
      def initialize(app)
        @app = app
      end

      def call(env)
        if env['PATH_INFO'] == '/health'
          [200, { 'Content-Type' => 'text/plain' }, ['OK']]
        else
          @app.call(env)
        end
      end
    end)

    # Set secure headers for production
    config.force_ssl = false # ALB handles SSL
    config.ssl_options = { redirect: false }
    
    # Configure secure cookies if behind HTTPS ALB
    if ENV['FORCE_SSL'] == 'true'
      config.session_store :cookie_store, {
        key: '_classroom_monitoring_session',
        secure: true,
        httponly: true,
        same_site: :lax
      }
    end
  end
end
