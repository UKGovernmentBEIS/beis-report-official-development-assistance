require "rails_helper"

RSpec.describe UpdateTransaction do
  let(:transaction) { create(:transaction, value: BigDecimal("101.01"), financial_quarter: 1) }
  let(:user) { double("user") }
  let(:report) { double("report") }

  let(:updater) do
    described_class.new(transaction: transaction, user: user, report: report)
  end

  let(:history_recorder) do
    instance_double(HistoryRecorder, call: double)
  end

  describe "#call" do
    before do
      allow(HistoryRecorder).to receive(:new).and_return(history_recorder)
    end

    context "when the change is persisted successfully" do
      before do
        allow(transaction).to receive(:save).and_return(true)
      end

      let(:expected_changes) do
        {
          "value" => [BigDecimal("101.01"), BigDecimal("202.02")],
          "financial_quarter" => [1, 2],
        }
      end

      it "asks the HistoryRecorder to handle the changes" do
        updater.call(attributes: {value: "202.02", financial_quarter: "2"})

        expect(HistoryRecorder).to have_received(:new).with(user: user)
        expect(history_recorder).to have_received(:call).with(
          changes: expected_changes,
          reference: "Update to Transaction",
          activity: transaction.parent_activity,
          trackable: transaction,
          report: report
        )
      end

      it "returns a successful result" do
        result = updater.call(attributes: {})

        expect(result.success?).to be true
      end
    end

    context "when the change is NOT persisted successfully" do
      before do
        allow(transaction).to receive(:save).and_return(false)
      end

      it "does NOT ask the HistoryRecorder to handle the changes" do
        updater.call(attributes: {value: "202.02", financial_quarter: "2"})

        expect(HistoryRecorder).not_to have_received(:new).with(user: user)
      end

      it "returns a failed result" do
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
