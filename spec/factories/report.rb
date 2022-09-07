FactoryBot.define do
  factory :report do
    description { Faker::Lorem.paragraph }
    state { :active }
    financial_quarter { FinancialQuarter.for_date(Date.today).to_i }
    financial_year { FinancialYear.for_date(Date.today).to_i }
    deadline { 1.year.from_now }

    association :fund, factory: :fund_activity
    association :organisation, factory: :partner_organisation

    trait :approved do
      state { :approved }
      deadline { 1.day.from_now }
    end
  end
end
