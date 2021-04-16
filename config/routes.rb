# frozen_string_literal: true

Rails.application.routes.draw do
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
    resource :dashboard, only: :show
    resources :users
    resources :activities, only: [:index] do
      collection do
        get "historic" => "activities#historic"
      end
    end
    resources :organisations, except: [:destroy] do
      resources :activities, except: [:index, :create, :destroy] do
        get "financials" => "activity_financials#show"
        get "details" => "activity_details#show"

        resource :children, controller: :activity_children, only: [:show, :create]

        get "comments" => "activity_comments#show"
      end
    end

    resources :reports, only: [:show, :edit, :update, :index] do
      resource :spending_breakdown, only: [:show], path: "spending"
      resource :state, only: [:edit, :update], controller: :reports_state
      resource :activity_upload, only: [:new, :show, :update]
      resource :planned_disbursement_upload, only: [:new, :show, :update]
      resource :transaction_upload, only: [:new, :show, :update]
      get "variance" => "report_variance#show"
      get "budgets" => "report_budgets#show"
    end

    concern :transactionable do
      resources :transactions
    end

    concern :budgetable do
      resources :budgets, only: [:new, :create, :show, :edit, :update]
    end

    concern :disbursement_plannable do
      resources :planned_disbursements, only: [:new, :create] do
        collection do
          constraints year: /\d{4}/, quarter: /[1-4]/ do
            get ":year/:quarter", to: "planned_disbursements#edit", as: "edit"
            patch ":year/:quarter", to: "planned_disbursements#update", as: "update"
            delete ":year/:quarter", to: "planned_disbursements#destroy", as: "destroy"
          end
        end
      end
    end

    resources :activities, only: [], concerns: [:transactionable, :budgetable, :disbursement_plannable] do
      resource :redaction, only: [:edit, :update], controller: :activity_redactions
      resources :steps, controller: "activity_forms"
      resources :implementing_organisations, only: [:new, :create, :edit, :update]
      resources :comments, only: [:new, :create, :edit, :update]
      resources :transfers, except: [:index]
    end

    resource :search, only: [:show]
  end

  # Static pages
  get "/pages/*id" => "pages#show", :as => :page, :format => false

  # Authentication
  get "auth/oauth2/callback" => "auth0#callback"
  get "auth/failure" => "auth0#failure"
  get "sign_out" => "application#sign_out"

  # Errors
  get "/404", to: "errors#not_found"
  get "/422", to: "errors#unacceptable"
  get "/500", to: "errors#internal_server_error"
end
