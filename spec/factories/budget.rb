FactoryBot.define do
  factory :budget do
    budget_type { 1 }
    financial_year { Date.current.next_year.year }
    value { BigDecimal("110.01") }
    currency { "gbp" }
    ingested { false }
    association :parent_activity, factory: :activity
    association :report, factory: :report

    trait :direct_newton do
      budget_type { Budget::BUDGET_TYPES["direct_newton_fund"] }
      association :parent_activity, factory: [:fund_activity, :newton]
    end

    trait :direct_gcrf do
      budget_type { Budget::BUDGET_TYPES["direct_global_challenges_research_fund"] }
      association :parent_activity, factory: [:fund_activity, :gcrf]
    end

    trait :transferred do
      budget_type { Budget::BUDGET_TYPES["transferred"] }
      association :providing_organisation, factory: :delivery_partner_organisation
    end

    trait :external_official_development_assistance do
      budget_type { Budget::BUDGET_TYPES["external_official_development_assistance"] }
    end

    trait :external_non_official_development_assistance do
      budget_type { Budget::BUDGET_TYPES["external_non_official_development_assistance"] }
    end
  end
end
