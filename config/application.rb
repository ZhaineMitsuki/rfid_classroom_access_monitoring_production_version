require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module App
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    config.time_zone = 'Asia/Manila'
    config.active_record.default_timezone = :local

    # Enable CORS
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*' # Allow all domains (for development)
        resource '*',
                 headers: :any,
                 methods: [:get, :post, :put, :patch, :delete, :options]
      end
    end

    # Asset pipeline configuration for ERB processing in CSS
    config.assets.precompile += %w( *.css.erb )
    config.assets.precompile += %w( TUP_Main.jpg )

    # Don't generate system test files.
    config.generators.system_tests = nil
  end
end
