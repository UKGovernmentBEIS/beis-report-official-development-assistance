FactoryBot.define do
  factory :comment do
    body { Faker::Lorem.paragraph }
    commentable { association(:project_activity) }
    association :owner, factory: :partner_organisation_user
    association :report

    trait :with_activity do
    end

    trait :with_refund do
      commentable { association(:refund) }
      commentable_type { "Refund" }
    end

    trait :with_adjustment do
      commentable { association(:adjustment) }
      commentable_type { "Adjustment" }
    end
  end
end
