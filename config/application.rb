# frozen_string_literal: true

require_relative "boot"

# Include each railties manually, excluding `active_storage/engine` and `action_mailbox`
%w[
  active_record/railtie
  action_controller/railtie
  action_view/railtie
  action_mailer/railtie
  active_job/railtie
  rails/test_unit/railtie
  sprockets/railtie
].each do |railtie|
  require railtie
rescue LoadError
end

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
    config.load_defaults 6.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Add IATI locales (:en is the default locale)
    config.i18n.load_path += Dir[Rails.root.join("config", "locales", "**", "*.{rb,yml}")]
    config.i18n.default_locale = :en
    config.i18n.enforce_available_locales = false

    config.active_job.queue_adapter = :sidekiq

    # GOV.UK Notify
    config.action_mailer.delivery_method = :notify
    config.action_mailer.deliver_later_queue_name = "mailers"
    config.action_mailer.notify_settings = {
      api_key: ENV["NOTIFY_KEY"],
    }
    config.action_mailer.default_url_options = {host: ENV["DOMAIN"]}

    config.skylight.environments += ["pentest", "staging"]
    config.skylight.probes << "active_job"

    # serve dynamic error pages
    config.exceptions_app = routes
  end
end
