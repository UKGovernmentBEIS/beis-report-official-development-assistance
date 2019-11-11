FactoryBot.define do
  factory :organisation do
    name { "My Organisation" }
    organisation_type { "10" }
    default_currency { "gbp" }
    language_code { "en" }
  end
end
