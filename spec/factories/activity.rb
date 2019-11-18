FactoryBot.define do
  factory :activity do
    title { Faker::Lorem.sentence }
    identifier { "GB-GOV-13-GCRF" }
    description { Faker::Lorem.paragraph }
    sector { "99" }
    status { "2" }
    recipient_region { "489" }
    flow { "10" }
    finance { "110" }
    aid_type { "A01" }
    tied_status { "3" }
    association :fund, factory: :fund
  end
end
