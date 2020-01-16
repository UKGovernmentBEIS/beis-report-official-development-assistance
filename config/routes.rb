# frozen_string_literal: true

Rails.application.routes.draw do
  scope module: "public" do
    get "health_check" => "base#health_check"
    root to: "visitors#index"
  end

  scope module: "staff" do
    resource :dashboard, only: :show
    resources :users
    resources :organisations, except: [:destroy] do
      resources :funds, except: [:destroy]
    end

    concern :activity do
      resources :activities, only: [:new, :create, :show] do
        resources :steps, controller: "activity_forms"
      end
    end

    concern :transactionable do
      resources :transactions, only: [:new, :create, :show, :edit, :update]
    end

    resources :funds, only: [], concerns: [:activity, :transactionable] do
      resources :programmes, only: [:new, :create, :show]
    end
    # TODO: Extend with more hierarchies using this format
    # resources :programmes, only: [], concerns: [:activity, :transactionable]
  end

  # Authentication
  get "auth/oauth2/callback" => "auth0#callback"
  get "auth/failure" => "auth0#failure"
  get "sign_out" => "application#sign_out"
end
