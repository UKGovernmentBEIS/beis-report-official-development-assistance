FactoryBot.define do
  factory :comment do
    comment { Faker::Lorem.paragraph }
    association :owner, factory: :delivery_partner_user
    association :report
    association :activity, factory: :project_activity
  end
end
