require "rails_helper"

RSpec.describe CreateBudget do
  let!(:service_owner) { create(:beis_organisation) }
  let(:activity) { create(:project_activity) }

  describe "#call" do
    it "sets the activity as the one this budget belongs to" do
      result = described_class.new(activity: activity).call
      expect(result.object.parent_activity).to eq(activity)
    end

    context "when the activity belongs to a partner organisation" do
      it "sets the value of report to the editable report for the activity" do
        activity.update(organisation: build_stubbed(:partner_organisation))
        editable_report_for_activity = create(:report, :active, organisation: activity.organisation, fund: activity.associated_fund)

        budget = described_class.new(activity: activity).call

        expect(budget.object.report).to eql editable_report_for_activity
      end
    end

    context "when the activity belongs to BEIS" do
      it "does not set the value of report" do
        activity.update(organisation: build_stubbed(:beis_organisation))
        _editable_report_for_activity = create(:report, :active, organisation: activity.organisation, fund: activity.associated_fund)

        budget = described_class.new(activity: activity).call

        expect(budget.object.report).to be_nil
      end
    end

    it "returns a successful result" do
      allow_any_instance_of(Budget).to receive(:valid?).and_return(true)
      allow_any_instance_of(Budget).to receive(:save).and_return(true)

      result = described_class.new(activity: activity).call(attributes: {})

      expect(result.success?).to be true
    end

    context "when the budget isn't valid" do
      it "returns a failed result" do
        allow_any_instance_of(Budget).to receive(:valid?).and_return(false)

        result = described_class.new(activity: activity).call(attributes: {})

        expect(result.success?).to be false
      end
    end

    context "when attributes are passed in" do
      it "sets the attributes passed in as budget attributes" do
        attributes = ActionController::Parameters.new(budget_type: 0).permit!
        result = described_class.new(activity: activity).call(attributes: attributes)
        expect(result.object.budget_type).to eq("direct")
      end

      subject { described_class.new(activity: activity) }
      it_behaves_like "sanitises monetary field"
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
