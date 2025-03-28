require "active_support/core_ext/integer/time"

# The test environment is used exclusively to run your application's
# test suite. You never need to work with it otherwise. Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs. Don't rely on the data there!

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # While tests run files are not watched, reloading is not necessary.
  config.enable_reloading = false

  # Eager loading loads your entire application. When running a single test locally,
  # this is usually not necessary, and can slow down your test suite. However, it's
  # recommended that you enable it in continuous integration systems to ensure eager
  # loading is working properly before deploying your code.
  config.eager_load = ENV["CI"].present?

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    "Cache-Control" => "public, max-age=#{1.hour.to_i}"
  }

  # Show full error reports and disable caching.
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.cache_store = :null_store

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = :none

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Disable caching for Action Mailer templates even if Action Controller
  # caching is enabled.
  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test
  config.action_mailer.default_options = {from: "hello@example.com"}

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raises error for missing translations.
  config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  config.action_view.annotate_rendered_view_with_filenames = false

  # Set a css_compressor so sassc-rails does not overwrite the compressor
  # See https://github.com/DFE-Digital/dfe-teachers-payment-service/commit/74ec587cfbe9aa6d0df01a72e99d70ffe9024748
  config.assets.css_compressor = nil

  config.active_job.queue_adapter = :test

  config.after_initialize do
    Bullet.enable = true
    Bullet.bullet_logger = true
    Bullet.raise = true # raise an error if n+1 query occurs
    Bullet.add_safelist type: :unused_eager_loading, class_name: "User", association: :organisation
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Activity", association: :organisation
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Activity", association: :child_activities
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Activity", association: :linked_activity
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Transaction", association: :provider
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Transaction", association: :receiver
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Activity", association: :parent
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Activity", association: :extending_organisation
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Activity", association: :implementing_organisations
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Activity", association: :commitment
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Activity", association: :budgets
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Report", association: :fund
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Budget", association: :providing_organisation
    Bullet.add_safelist type: :unused_eager_loading, class_name: "HistoricalEvent", association: :report
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Activity", association: :parent_activity
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Activity", association: :implementing_org_participations
    Bullet.add_safelist type: :unused_eager_loading, class_name: "OrgParticipation", association: :organisation
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Comment", association: :owner
    Aws.config.update(stub_responses: true)
  end

  config.hosts = [
    /test.local/,
    /localhost/
  ]
end
