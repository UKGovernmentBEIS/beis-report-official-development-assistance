FactoryBot.define do
  factory :adjustment_detail do
    adjustment_id { create(:adjustment) }
    user { create(:delivery_partner_user) }
    adjustment_type { "Actual" }
  end
end
