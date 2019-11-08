# frozen_string_literal: true

Rails.application.routes.draw do
  get "health_check" => "application#health_check"

  resource :dashboard, controller: "users/dashboards", only: :show

  root to: "public/visitors#index"

  # Authentication
  get "auth/oauth2/callback" => "auth0#callback"
  get "auth/failure" => "auth0#failure"
  get "sign_out" => "users/base#sign_out"
end
