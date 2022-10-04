FactoryBot.define do
  factory :org_participation do
    association :organisation, factory: :partner_organisation
    association :activity, factory: :programme_activity
    role { :implementing }

    trait :inactive_organisation do
      association :organisation, factory: [:partner_organisation, :inactive]
    end
  end
end
