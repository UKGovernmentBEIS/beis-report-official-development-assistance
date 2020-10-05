require "rails_helper"

RSpec.describe PlannedDisbursement, type: :model do
  let(:activity) { build(:activity) }

  describe "validations" do
    it { should validate_presence_of(:planned_disbursement_type) }
    it { should validate_presence_of(:period_start_date) }
    it { should validate_presence_of(:currency) }
    it { should validate_presence_of(:value) }

    context "when the activity belongs to a delivery partner organisation" do
      before { activity.update(organisation: build_stubbed(:delivery_partner_organisation)) }

      it "should validate the prescence of report" do
        transaction = build_stubbed(:transaction, parent_activity: activity, report: nil)
        expect(transaction.valid?).to be false
      end
    end

    context "when the activity belongs to BEIS" do
      before { activity.update(organisation: build_stubbed(:beis_organisation)) }

      it "should not validate the prescence of report" do
        transaction = build_stubbed(:transaction, parent_activity: activity, report: nil)
        expect(transaction.valid?).to be true
      end
    end
  end

  describe "#unknown_receiving_organisation_type?" do
    it "returns true when receiving organisation type is 0" do
      planned_disbursement = create(:planned_disbursement, receiving_organisation_type: "0")
      expect(planned_disbursement.unknown_receiving_organisation_type?).to be true

      planned_disbursement.update(receiving_organisation_type: "10")
      expect(planned_disbursement.unknown_receiving_organisation_type?).to be false
    end
  end

  describe "sanitation" do
    it { should strip_attribute(:providing_organisation_reference) }
    it { should strip_attribute(:receiving_organisation_reference) }
  end
end
