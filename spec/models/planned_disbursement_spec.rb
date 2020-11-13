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
end
