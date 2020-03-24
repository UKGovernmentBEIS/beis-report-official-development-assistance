# frozen_string_literal: true

Capybara.asset_host = "http://localhost:3000"
Capybara.app_host = "http://localhost"
Capybara.always_include_port = true
Capybara.javascript_driver = :selenium_headless

# Required to make Capybara in the browser able to select GOVUK styled radio buttons
Capybara.automatic_label_click = true
