# frozen_string_literal: true

Rails.application.routes.draw do
  devise_scope :user do
    devise_for :users, controllers: {sessions: "users/sessions"}
    get :edit_mobile_number, to: "users/sessions#edit_mobile_number"
  end

  # If the DOMAIN env var is present, and the request doesn't come from that
  # hostname, redirect us to the canonical hostname with the path and query string present
  if ENV["CANONICAL_HOSTNAME"].present?
    constraints(host: Regexp.new("^(?!#{ENV["CANONICAL_HOSTNAME"]})")) do
      match "/(*path)" => redirect(host: ENV["CANONICAL_HOSTNAME"]), :via => [:all]
    end
  end

  scope module: "public" do
    get "health_check" => "base#health_check"
    root to: "visitors#index"
  end

  scope module: "staff" do
    get "home", to: "home#show"
    resources :users
    resources :activities, only: [:index]

    roles = %w[implementing_organisations partner_organisations matched_effort_providers external_income_providers]
    constraints role: /#{roles.join("|")}/ do
      get "organisations/(:role)", to: "organisations#index", defaults: {role: "partner_organisations"}, as: :organisations
      get "organisations/(:role)/new", to: "organisations#new", as: :new_organisation
    end

    resources :exports, only: [:index] do
      get "external_income", on: :collection
      get "budgets", on: :collection
      get "spending_breakdown", on: :collection
    end

    namespace :exports do
      resources :organisations, only: [:show] do
        get "actuals", on: :member
        # IATI XML exports
        get "iati/programme_activities", on: :member, to: "organisations#programme_activities"
        get "iati/project_activities", on: :member, to: "organisations#project_activities"
        get "iati/third_party_project_activities", on: :member, to: "organisations#third_party_project_activities"
        get :external_income, on: :member
        get :budgets, on: :member
        get :spending_breakdown, on: :member
      end
    end

    resources :organisations, except: [:destroy, :index, :new] do
      get "reports" => "organisation_reports#index"
      resources :activities, except: [:create, :destroy] do
        collection do
          get "historic" => "activities#historic"
        end
        resource :children, controller: :activity_children, only: [:create]

        Activity::Tab::VALID_TAB_NAMES.each do |tab|
          get tab, to: "activities#show", defaults: {tab: tab}
        end
      end
      resource :level_b_activity_upload, only: [:new]
    end

    resources :reports, only: [:new, :create, :show, :edit, :update, :index] do
      resource :state, only: [:edit, :update], controller: :reports_state
      resource :activity_upload, only: [:new, :show, :update]
      resource :forecast_upload, only: [:new, :show, :update]
      resource :actual_upload, only: [:new, :show, :update]
      get "variance" => "report_variance#show"
      get "forecasts" => "report_forecasts#show"
      get "actuals" => "report_actuals#show"
      get "budgets" => "report_budgets#show"
      get "activities" => "report_activities#show"
      get "comments" => "report_comments#show"
      namespace :uploads do
        resource :actual_history, only: [:new, :update]
      end
    end

    concern :transactionable do
      resources :actuals
    end

    concern :budgetable do
      resources :budgets
    end

    concern :forecastable do
      resources :forecasts, only: [:new, :create] do
        collection do
          constraints year: /\d{4}/, quarter: /[1-4]/ do
            get ":year/:quarter", to: "forecasts#edit", as: "edit"
            patch ":year/:quarter", to: "forecasts#update", as: "update"
            delete ":year/:quarter", to: "forecasts#destroy", as: "destroy"
          end
        end
      end
    end

    concern :matched_effortable do
      resources :matched_efforts
    end

    concern :external_incomeable do
      resources :external_incomes, only: [:new, :create, :edit, :update, :destroy]
    end

    resources :activities, only: [], concerns: [:transactionable, :budgetable, :forecastable, :matched_effortable, :external_incomeable] do
      resource :redaction, only: [:edit, :update], controller: :activity_redactions
      resources :steps, controller: "activity_forms"
      resources :implementing_organisations, only: [:new, :create, :destroy]
      resources :comments, only: [:new, :create, :edit, :update], controller: "activity_comments"
      resources :outgoing_transfers, except: [:index]
      resources :incoming_transfers, except: [:index]
      resources :refunds, except: [:index]
      resources :adjustments, only: [:new, :create, :show]
    end

    resource :search, only: [:show]
  end

  # Static pages
  get "/pages/*id" => "pages#show", :as => :page, :format => false

  # Errors
  get "/404", to: "errors#not_found"
  get "/422", to: "errors#unacceptable"
  get "/500", to: "errors#internal_server_error"
end
