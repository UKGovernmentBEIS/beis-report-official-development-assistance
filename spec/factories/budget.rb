FactoryBot.define do
  factory :budget do
    budget_type { 1 }
    financial_year { Date.current.next_year.year }
    value { BigDecimal("110.01") }
    currency { "gbp" }
    ingested { false }
    association :parent_activity, factory: :project_activity
    association :report, factory: :report

    trait :direct_newton do
      budget_type { Budget::BUDGET_TYPES["direct_newton_fund"] }
      association :parent_activity, factory: [:fund_activity, :newton]
    end

    trait :direct_gcrf do
      budget_type { Budget::BUDGET_TYPES["direct_global_challenges_research_fund"] }
      association :parent_activity, factory: [:fund_activity, :gcrf]
    end

    trait :other_official_development_assistance do
      budget_type { Budget::BUDGET_TYPES["other_official_development_assistance"] }
      providing_organisation_name { Faker::Company.name }
      providing_organisation_type { "Other NGO" }
    end
  end
end
