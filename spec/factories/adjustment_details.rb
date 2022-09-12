FactoryBot.define do
  factory :adjustment_detail do
    adjustment_id { create(:adjustment) }
    user { create(:partner_organisation_user) }
    adjustment_type { "Actual" }
  end
end
