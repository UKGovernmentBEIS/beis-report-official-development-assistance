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
      resources :activities, except: [:destroy]
      resources :funds, only: [:create] do
        resources :programmes, only: [:create]
      end
    end

    concern :transactionable do
      resources :transactions, only: [:new, :create, :show, :edit, :update]
    end

    concern :budgetable do
      resources :budgets, only: [:new, :create, :show, :edit, :update]
    end

    resources :activities, only: [], concerns: [:transactionable, :budgetable] do
      resources :steps, controller: "activity_forms"
    end
  end

  # Authentication
  get "auth/oauth2/callback" => "auth0#callback"
  get "auth/failure" => "auth0#failure"
  get "sign_out" => "application#sign_out"
end
