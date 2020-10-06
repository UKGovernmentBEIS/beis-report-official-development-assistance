require "rails_helper"

RSpec.describe CreatePlannedDisbursement do
  let(:activity) { create(:activity) }

  describe "#call" do
    subject { described_class.new(activity: create(:activity)) }
    it_behaves_like "sanitises monetary field"

    context "when the planned disbursement is valid" do
      it "sets the parent activity" do
        result = described_class.new(activity: activity).call
        expect(result.object.parent_activity).to eq(activity)
      end

      context "when financial quarter and year are provided" do
        it "sets the period start and end dates" do
          financial_quarter = "1"
          financial_year = "2020"
          result = described_class.new(activity: activity).call(attributes: {financial_quarter: financial_quarter, financial_year: financial_year})
          expect(result.object.period_start_date).to eq "2020-04-01".to_date
          expect(result.object.period_end_date).to eq "2020-06-30".to_date
        end
      end

      it "returns a successful result" do
        allow_any_instance_of(PlannedDisbursement).to receive(:valid?).and_return(true)
        allow_any_instance_of(PlannedDisbursement).to receive(:save).and_return(true)

        result = described_class.new(activity: activity).call(attributes: {})

        expect(result.success?).to be true
      end
    end

    context "when the planned disbursement isn't valid" do
      it "returns a failed result" do
        allow_any_instance_of(PlannedDisbursement).to receive(:valid?).and_return(false)

        result = described_class.new(activity: activity).call(attributes: {})

        expect(result.success?).to be false
      end
    end

    context "when the transaction isn't valid" do
      it "returns a failed result" do
        allow_any_instance_of(Transaction).to receive(:valid?).and_return(false)

        result = described_class.new(activity: activity).call(attributes: {})

        expect(result.success?).to be false
      end
    end

    context "when the activity belongs to BEIS" do
      it "does not set the report" do
        activity.update(organisation: build_stubbed(:beis_organisation))
        result = described_class.new(activity: activity).call
        expect(result.object.report).to be_nil
      end
    end

    context "when the activity belongs to a delivery partner organisation" do
      it "does set the report" do
        activity.update(organisation: build_stubbed(:delivery_partner_organisation))
        editable_report_for_activity = create(:report, state: :active, organisation: activity.organisation, fund: activity.associated_fund)
        result = described_class.new(activity: activity).call
        expect(result.object.report).to eql editable_report_for_activity
      end
    end

    context "when known attributes are passed in" do
      it "sets the attributes passed in as planned disbursement attributes" do
        attributes = ActionController::Parameters.new(value: 10000.50).permit!

        result = described_class.new(activity: activity).call(attributes: attributes)

        expect(result.object.value).to eq(10000.50)
      end
    end

    context "when unknown attributes are passed in" do
      it "raises an error" do
        attributes = ActionController::Parameters.new(foo: "bar").permit!

        expect { described_class.new(activity: activity).call(attributes: attributes) }
          .to raise_error(ActiveModel::UnknownAttributeError)
      end
    end
  end
end
