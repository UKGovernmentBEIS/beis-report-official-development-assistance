# frozen_string_literal: true

Capybara.asset_host = "http://localhost:3000"
Capybara.app_host = "http://localhost"
Capybara.always_include_port = true
Capybara.javascript_driver = :selenium_headless
Capybara.server = :puma, {Silent: true}

# Required to make Capybara in the browser able to select GOVUK styled radio buttons
Capybara.automatic_label_click = true
Capybara.register_driver :rack_test do |app|
  # Increase redirect_limit to prevent `Capybara::InfiniteRedirect` error being
  # triggered due to the multiple steps that are skipped in
  # ActivityFormsController#show

  Capybara::RackTest::Driver.new(app, respect_data_method: true, redirect_limit: 20)
end
