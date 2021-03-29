require "rails_helper"

RSpec.describe UpdateBudget do
  let(:budget) { create(:budget) }

  describe "#call" do
    it "returns a successful result" do
      allow(budget).to receive(:valid?).and_return(true)
      allow(budget).to receive(:save).and_return(true)

      result = described_class.new(budget: budget).call(attributes: {})

      expect(result.success?).to be true
    end

    context "when the budget isn't valid" do
      it "returns a failed result" do
        allow(budget).to receive(:valid?).and_return(false)

        result = described_class.new(budget: budget).call(attributes: {})

        expect(result.success?).to be false
      end
    end

    context "when attributes are passed in" do
      it "sets the attributes passed in as budget attributes" do
        attributes = ActionController::Parameters.new(budget_type: "1").permit!

        result = described_class.new(budget: budget).call(attributes: attributes)

        expect(result.object.budget_type).to eq(1)
      end

      subject { described_class.new(budget: budget) }
      it_behaves_like "sanitises monetary field"
    end

    context "when unknown attributes are passed in" do
      it "raises an error" do
        attributes = ActionController::Parameters.new(foo: "bar").permit!

        expect { described_class.new(budget: budget).call(attributes: attributes) }
          .to raise_error(ActiveModel::UnknownAttributeError)
      end
    end
  end
end
