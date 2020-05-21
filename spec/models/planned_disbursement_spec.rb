require "rails_helper"

RSpec.describe PlannedDisbursement, type: :model do
  describe "validations" do
    it { should validate_presence_of(:planned_disbursement_type) }
    it { should validate_presence_of(:period_start_date) }
    it { should validate_presence_of(:currency) }
    it { should validate_presence_of(:value) }
  end

  describe "#unknown_receiving_organisation_type?" do
    it "returns true when receiving organisation type is 0" do
      planned_disbursement = create(:planned_disbursement, receiving_organisation_type: "0")
      expect(planned_disbursement.unknown_receiving_organisation_type?).to be true

      planned_disbursement.update(receiving_organisation_type: "10")
      expect(planned_disbursement.unknown_receiving_organisation_type?).to be false
    end
  end
end
