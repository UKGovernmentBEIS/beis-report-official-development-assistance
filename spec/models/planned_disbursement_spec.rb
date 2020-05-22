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

  describe "validations" do
    context "when the planned_disbursement_type is blank" do
      it "displays the appropriate error message" do
        planned_disbursement = build(:planned_disbursement, planned_disbursement_type: nil)
        expect(planned_disbursement.valid?).to be_falsey
        expect(planned_disbursement.errors[:planned_disbursement_type]).to include I18n.t("activerecord.errors.models.planned_disbursement.attributes.planned_disbursement_type.blank")
      end
    end
    context "when period_start_date is not blank" do
      let(:planned_disbursement) { build(:planned_disbursement) }

      it "does not allow a period_start_date more than 10 years ago" do
        planned_disbursement = build(:planned_disbursement, period_start_date: 11.years.ago)
        expect(planned_disbursement.valid?).to be_falsey
        expect(planned_disbursement.errors[:period_start_date]).to include I18n.t("activerecord.errors.models.planned_disbursement.attributes.period_start_date.between", min: 10, max: 25)
      end

      it "does not allow a period_start_date more than 25 years in the future" do
        planned_disbursement = build(:planned_disbursement, period_start_date: 26.years.from_now)
        expect(planned_disbursement.valid?).to be_falsey
      end

      it "allows a period_start_date between 10 years ago and 25 years in the future" do
        planned_disbursement = build(:planned_disbursement, period_start_date: Date.today)
        expect(planned_disbursement.valid?).to be_truthy
      end
    end

    context "when the period_end_date is not blank" do
      let(:planned_disbursement) { build(:planned_disbursement) }

      it "does not allow the period_end_date to be before the period_start_date" do
        planned_disbursement = build(:planned_disbursement, period_start_date: Date.today + 1.month, period_end_date: Date.today)
        expect(planned_disbursement.valid?).to be_falsey
        expect(planned_disbursement.errors[:period_end_date]).to include I18n.t("activerecord.errors.validators.end_date_not_before_start_date")
      end

      it "does not allow a period_end_date more than 10 years ago" do
        planned_disbursement = build(:planned_disbursement, period_start_date: 12.years.ago, period_end_date: 11.years.ago)
        expect(planned_disbursement.valid?).to be_falsey
        expect(planned_disbursement.errors[:period_end_date]).to include I18n.t("activerecord.errors.models.planned_disbursement.attributes.period_end_date.between", min: 10, max: 25)
      end

      it "does not allow a period_end_date more than 25 years in the future" do
        planned_disbursement = build(:planned_disbursement, period_end_date: 26.years.from_now)
        expect(planned_disbursement.valid?).to be_falsey
      end

      it "allows a period_end_date between 10 years ago and 25 years in the future" do
        planned_disbursement = build(:planned_disbursement, period_start_date: Date.yesterday, period_end_date: Date.today)
        expect(planned_disbursement.valid?).to be_truthy
      end
    end
  end
end
