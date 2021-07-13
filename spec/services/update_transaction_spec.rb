require "rails_helper"

RSpec.describe UpdateTransaction do
  let(:transaction) { create(:transaction) }
  let(:user) { double("user") }
  let(:report) { double("report") }

  let(:updater) do
    described_class.new(transaction: transaction, user: user, report: report)
  end

  describe "#call" do
    context "when the transaction is valid" do
      before do
        allow(transaction).to receive(:valid?).and_return(true)
        allow(transaction).to receive(:save).and_return(true)
      end

      it "returns a successful result" do
        result = updater.call(attributes: {})

        expect(result.success?).to be true
      end

      context "when the change is persisted successfully" do
        it "asks the HistoryRecorder to handle the changes"
      end

      context "when the change is NOT persisted successfully" do
        it "does NOT ask the HistoryRecorder to handle the changes"
      end
    end

    context "when the transaction isn't valid" do
      it "returns a failed result" do
        allow(transaction).to receive(:valid?).and_return(false)

        result = updater.call(attributes: {})

        expect(result.success?).to be false
      end
    end

    context "when attributes are passed in" do
      it "sets the attributes passed in as transaction attributes" do
        attributes = ActionController::Parameters.new(description: "foo").permit!

        result = updater.call(attributes: attributes)

        expect(result.object.description).to eq("foo")
      end

      subject { updater }
      it_behaves_like "sanitises monetary field"
    end

    context "when unknown attributes are passed in" do
      it "raises an error" do
        attributes = ActionController::Parameters.new(foo: "bar").permit!

        expect { updater.call(attributes: attributes) }
          .to raise_error(ActiveModel::UnknownAttributeError)
      end
    end
  end
end
