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
