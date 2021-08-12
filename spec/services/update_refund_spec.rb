require "rails_helper"

RSpec.describe UpdateRefund do
  let(:refund) { create(:refund) }

  describe "#call" do
    it "returns a successful result" do
      allow(refund).to receive(:valid?).and_return(true)
      allow(refund).to receive(:save).and_return(true)

      result = described_class.new(refund: refund).call(attributes: {})

      expect(result.success?).to be true
    end

    context "when the refund isn't valid" do
      it "returns a failed result" do
        allow(refund).to receive(:valid?).and_return(false)

        result = described_class.new(refund: refund).call(attributes: {})

        expect(result.success?).to be false
      end
    end

    context "when attributes are passed in" do
      it "sets the attributes passed in as refund attributes" do
        attributes = ActionController::Parameters.new(comment: "abc").permit!

        result = described_class.new(refund: refund).call(attributes: attributes)

        expect(result.object.comment).to eq("abc")
      end
    end

    context "when unknown attributes are passed in" do
      it "raises an error" do
        attributes = ActionController::Parameters.new(foo: "bar").permit!

        expect { described_class.new(refund: refund).call(attributes: attributes) }
          .to raise_error(ActiveModel::UnknownAttributeError)
      end
    end
  end
end
