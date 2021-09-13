require "rails_helper"

RSpec.describe AdjustmentDetail, type: :model do
  it { should belong_to(:adjustment) }
  it { should belong_to(:user) }

  it { should validate_inclusion_of(:adjustment_type).in_array(["Refund", "Actual"]) }
end
