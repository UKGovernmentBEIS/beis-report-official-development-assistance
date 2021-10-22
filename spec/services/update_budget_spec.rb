require "rails_helper"

RSpec.describe UpdateBudget do
  let(:budget) { create(:budget) }
  let(:user) { create(:delivery_partner_user) }
  let(:history_recorder) { double("HistoryRecorder", call: nil) }

  subject { described_class.new(budget: budget, user: user) }

  let!(:report) do
    create(:report, organisation: budget.parent_activity.organisation, fund: budget.parent_activity.associated_fund)
  end

  before do
    allow(HistoryRecorder).to receive(:new).with(user: user).and_return(history_recorder)
  end

  describe "#call" do
    context "when the budget is valid" do
      before do
        allow(budget).to receive(:valid?).and_return(true)
      end

      let(:attributes) { {} }
      let(:result) { subject.call(attributes: attributes) }

      it "returns a successful result" do
        expect(result.success?).to be true
      end

      it "records a historic event" do
        expect(history_recorder).to receive(:call).with(
          changes: {},
          reference: "Change to Budget",
          activity: budget.parent_activity,
          trackable: budget,
          report: report
        )

        result
      end

      context "when attributes are passed in" do
        let(:attributes) do
          ActionController::Parameters.new(
            budget_type: 1,
            value: 100
          ).permit!
        end

        it "sets the attributes passed in as budget attributes" do
          expect(result.object.budget_type).to eq("other_official")
        end

        it "records the attributes in the historic event" do
          expect(history_recorder).to receive(:call).with(
            changes: {
              budget_type: [budget.budget_type, "other_official"],
              value: [budget.value, 100],
            },
            reference: "Change to Budget",
            activity: budget.parent_activity,
            trackable: budget,
            report: report
          )

          result
        end
      end
    end

    context "when the budget isn't valid" do
      it "returns a failed result" do
        allow(budget).to receive(:valid?).and_return(false)

        result = subject.call(attributes: {})

        expect(result.success?).to be false
      end
    end

    context "when unknown attributes are passed in" do
      it "raises an error" do
        attributes = ActionController::Parameters.new(foo: "bar").permit!

        expect { subject.call(attributes: attributes) }
          .to raise_error(ActiveModel::UnknownAttributeError)
      end
    end

    it_behaves_like "sanitises monetary field"
  end
end
