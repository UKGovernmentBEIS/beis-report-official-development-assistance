require "rails_helper"

RSpec.describe CreateTransaction do
  let(:activity) { create(:activity) }

  describe "#call" do
    it "sets the parent activity as the one this transaction belongs to" do
      result = described_class.new(activity: activity).call
      expect(result.object.parent_activity).to eq(activity)
    end

    it "returns a successful result" do
      allow_any_instance_of(Transaction).to receive(:valid?).and_return(true)
      allow_any_instance_of(Transaction).to receive(:save).and_return(true)

      result = described_class.new(activity: activity).call(attributes: {})

      expect(result.success?).to be true
    end

    context "when the transaction isn't valid" do
      it "returns a failed result" do
        allow_any_instance_of(Transaction).to receive(:valid?).and_return(false)

        result = described_class.new(activity: activity).call(attributes: {})

        expect(result.success?).to be false
      end
    end

    context "when attributes are passed in" do
      it "sets the attributes passed in as transaction attributes" do
        attributes = ActionController::Parameters.new(description: "foo").permit!

        result = described_class.new(activity: activity).call(attributes: attributes)

        expect(result.object.description).to eq("foo")
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
