require "rails_helper"

RSpec.describe PlannedDisbursement, type: :model do
  describe "validations" do
    it { should validate_presence_of(:planned_disbursement_type) }
    it { should validate_presence_of(:period_start_date) }
    it { should validate_presence_of(:currency) }
    it { should validate_presence_of(:value) }
  end
end
