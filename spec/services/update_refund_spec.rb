require "rails_helper"

RSpec.describe UpdateRefund do
  let(:refund) { create(:refund, value: BigDecimal("101.01"), financial_quarter: 1) }
  let(:user) { create(:partner_organisation_user) }
  let(:history_recorder) { instance_double(HistoryRecorder, call: double) }
  let(:updater) { described_class.new(refund: refund, user: user) }
  let!(:original_comment) { refund.comment.body }

  before do
    allow(HistoryRecorder).to receive(:new).and_return(history_recorder)
  end

  describe "#call" do
    context "when the update is successful" do
      let(:expected_changes) do
        {
          "value" => [-BigDecimal("101.01"), -BigDecimal("202.02")],
          "financial_quarter" => [1, 2],
          "comment" => [original_comment, "Updated text"]
        }
      end

      before do
        allow(refund).to receive(:save).and_return(true)
      end

      it "returns a successful result" do
        result = updater.call(attributes: {})

        expect(result.success?).to be true
      end

      it "uses HistoryRecorder to record a historical event" do
        updater.call(attributes: {value: "202.02", financial_quarter: "2", comment: "Updated text"})

        expect(HistoryRecorder).to have_received(:new).with(user: user)
        expect(history_recorder).to have_received(:call).with(
          changes: expected_changes,
          reference: "Update to Refund",
          activity: refund.parent_activity,
          trackable: refund,
          report: refund.report
        )
      end
    end

    context "when the refund isn't valid" do
      before do
        allow(refund).to receive(:valid?).and_return(false)
      end

      it "returns a failed result" do
        result = updater.call(attributes: {})

        expect(result.success?).to be false
      end

      it "does not record a historical event" do
        updater.call(attributes: {})

        expect(HistoryRecorder).to_not have_received(:new)
      end
    end

    context "when attributes are passed in" do
      it "sets the attributes passed in as refund attributes" do
        attributes = ActionController::Parameters.new(comment: "abc").permit!

        result = updater.call(attributes: attributes)

        expect(result.object.comment.body).to eq("abc")
      end
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
