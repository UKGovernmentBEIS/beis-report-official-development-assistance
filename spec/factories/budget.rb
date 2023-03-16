FactoryBot.define do
  factory :budget do
    budget_type { "direct" }
    financial_year { Date.current.next_year.year }
    value { BigDecimal("110.01") }
    currency { "gbp" }
    ingested { false }
    association :parent_activity, factory: :project_activity
    association :report, factory: :report

    trait :direct do
      budget_type { "direct" }
      association :parent_activity, factory: [:fund_activity, :newton]
    end

    trait :other_official_development_assistance do
      budget_type { "other_official" }
      providing_organisation_name { Faker::Company.name }
      providing_organisation_type { "Other NGO" }
    end

    trait "with_revisions" do
      transient { number_of_revisions { 1 } }

      after(:create) do |budget, evaluator|
        evaluator.number_of_revisions.times do
          new_value = budget.value + BigDecimal("50.00")

          budget.update(value: new_value)
        end
      end
    end
  end
end
