require "rails_helper"

RSpec.describe UpdateTransaction do
  let(:transaction) { create(:transaction) }

  describe "#call" do
    it "returns a successful result" do
      allow(transaction).to receive(:valid?).and_return(true)
      allow(transaction).to receive(:save).and_return(true)

      result = described_class.new(transaction: transaction).call(attributes: {})

      expect(result.success?).to be true
    end

    context "when the transaction isn't valid" do
      it "returns a failed result" do
        allow(transaction).to receive(:valid?).and_return(false)

        result = described_class.new(transaction: transaction).call(attributes: {})

        expect(result.success?).to be false
      end
    end

    context "when attributes are passed in" do
      it "sets the attributes passed in as transaction attributes" do
        attributes = ActionController::Parameters.new(reference: "foo").permit!

        result = described_class.new(transaction: transaction).call(attributes: attributes)

        expect(result.object.reference).to eq("foo")
      end

      subject { described_class.new(transaction: transaction) }
      it_behaves_like "sanitises monetary field"
    end

    context "when unknown attributes are passed in" do
      it "raises an error" do
        attributes = ActionController::Parameters.new(foo: "bar").permit!

        expect { described_class.new(transaction: transaction).call(attributes: attributes) }
          .to raise_error(ActiveModel::UnknownAttributeError)
      end
    end
  end
end
