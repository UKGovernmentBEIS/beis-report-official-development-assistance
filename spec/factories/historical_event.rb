FactoryBot.define do
  factory :historical_event do
    user { create(:partner_organisation_user) }
    activity { create(:project_activity) }
    trackable { activity }
    report { create(:report) }
    value_changed { "name" }
    new_value { Faker::Lorem.sentence }
    previous_value { Faker::Lorem.sentence }
    reference { "Update to activity purpose" }
  end
end
