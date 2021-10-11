FactoryBot.define do
  factory :comment do
    body { Faker::Lorem.paragraph }
    commentable { association(:project_activity) }
    association :owner, factory: :delivery_partner_user
    association :report
  end
end
