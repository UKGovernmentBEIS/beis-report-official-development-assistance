require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Roda
  class Application < Rails::Application
    config.generators do |g|
      g.test_framework :rspec,
        fixtures: true,
        view_specs: false,
        helper_specs: false,
        routing_specs: false,
        controller_specs: false,
        request_specs: false
      g.fixture_replacement :factory_bot, dir: "spec/factories"

      # Use UUIDs as primary keys by default
      g.orm :active_record, primary_key_type: :uuid
    end

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # No longer add autoloaded paths into `$LOAD_PATH`. This means that you won't be able
    # to manually require files that are managed by the autoloader, which you shouldn't do anyway.
    #
    # This will reduce the size of the load path, making `require` faster if you don't use bootsnap, or reduce the size
    # of the bootsnap cache if you use it.
    config.add_autoload_paths_to_load_path = false

    # Placed here as part of migrating to 7.1 settings, see commit message for reasoning
    Rails.application.config.active_record.encryption.hash_digest_class = OpenSSL::Digest::SHA256
    Rails.application.config.active_record.encryption.support_sha1_for_non_deterministic_encryption = true

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Add IATI locales (:en is the default locale)
    config.i18n.load_path += Dir[Rails.root.join("config", "locales", "**", "*.{rb,yml}")]
    config.i18n.default_locale = :en
    config.i18n.enforce_available_locales = false

    config.active_job.queue_adapter = :sidekiq

    # Set up YAML as the default serializer from Rails 7.1
    config.active_record.default_column_serializer = YAML

    config.active_record.yaml_column_permitted_classes = [
      ActiveSupport::TimeWithZone,
      ActiveSupport::TimeZone,
      BigDecimal,
      Date,
      Time
    ]

    # GOV.UK Notify
    config.action_mailer.delivery_method = :notify
    config.action_mailer.deliver_later_queue_name = "mailers"
    config.action_mailer.notify_settings = {
      api_key: ENV["NOTIFY_KEY"]
    }
    config.action_mailer.default_url_options = {host: ENV["DOMAIN"]}

    # serve dynamic error pages
    config.exceptions_app = routes

    config.time_zone = "London"

    config.active_record.encryption.primary_key = ENV["ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY"]
    config.active_record.encryption.deterministic_key = ENV["ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY"]
    config.active_record.encryption.key_derivation_salt = ENV["ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT"]

    # Default headers
    config.action_dispatch.default_headers["X-XSS-Protection"] = "0"

    config.host_authorization = {exclude: ->(request) { request.path =~ /health(_|-)check/ }}

    # configure default form builder
    config.action_view.default_form_builder = "RodaFormBuilder::FormBuilder"

    # Don't use XHR when submitting forms
    Rails.application.config.action_view.form_with_generates_remote_forms = false
  end
end
