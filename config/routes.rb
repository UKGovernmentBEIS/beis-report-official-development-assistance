# frozen_string_literal: true

Rails.application.routes.draw do
  scope module: "public" do
    get "health_check" => "base#health_check"
    root to: "visitors#index"

    get "privacy-policy" => "privacy_policy#index"
    get "cookie-statement" => "cookie_statement#index"
    get "accessibility-statement" => "accessibility_statement#index"
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
      resources :activities, except: [:index, :destroy] do
        get "financials" => "activity_financials#show"
        get "details" => "activity_details#show"
        get "children" => "activity_children#show"
        get "comments" => "activity_comments#show"
      end
    end

    resources :reports, only: [:show, :edit, :update, :index] do
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
      resource :extending_organisations, only: [:edit, :update]
      resources :implementing_organisations, only: [:new, :create, :edit, :update]
      resources :comments, only: [:new, :create, :edit, :update]
    end
  end

  # Authentication
  get "auth/oauth2/callback" => "auth0#callback"
  get "auth/failure" => "auth0#failure"
  get "sign_out" => "application#sign_out"

  # Errors
  get "/404", to: "errors#not_found"
  get "/422", to: "errors#unacceptable"
  get "/500", to: "errors#internal_server_error"
end
