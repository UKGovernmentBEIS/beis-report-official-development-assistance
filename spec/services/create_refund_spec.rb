require "rails_helper"

RSpec.describe CreateRefund do
  let(:activity) { build(:project_activity) }
  let(:report) { build(:report) }
  let(:user) { build(:delivery_partner_user) }
  let(:refund) { build(:refund) }
  let(:history_recorder) { instance_double("HistoryRecorder", call: nil) }

  let(:creator) { described_class.new(activity: activity, user: user) }

  before do
    allow(Refund).to receive(:new).and_return(refund)
    allow(HistoryRecorder).to receive(:new).with(user: user).and_return(history_recorder)
  end

  describe "#call" do
    subject { creator.call(attributes: attributes) }

    context "when there is an editable report for the activity" do
      before do
        allow(Report).to receive(:editable_for_activity) { report }
      end

      context "when the attributes are valid" do
        let(:attributes) do
          {
            value: 100.10,
            financial_quarter: 1,
            financial_year: 2020,
            comment: "Some words",
          }
        end

        it "creates a refund" do
          expect(refund).to receive(:save).at_least(:once)

          created_refund = subject

          expect(created_refund).to be_a(Refund)

          expect(created_refund.parent_activity).to eq(activity)
          expect(created_refund.report).to eq(report)
          expect(created_refund.value).to eq(-100.10)
          expect(created_refund.financial_quarter).to eq(1)
          expect(created_refund.financial_year).to eq(2020)
          expect(created_refund.comment.body).to eq("Some words")
          expect(subject.comment.report).to eq(report)
        end

        it "creates historical events" do
          expected_changes = {
            value: [nil, -attributes[:value].to_d.abs],
            financial_quarter: [nil, attributes[:financial_quarter]],
            financial_year: [nil, attributes[:financial_year]],
            comment: [nil, attributes[:comment]],
          }

          subject

          expect(history_recorder).to have_received(:call).with(
            changes: expected_changes,
            reference: "Creation of Refund",
            activity: refund.parent_activity,
            trackable: refund,
            report: refund.report
          )
        end
      end

      context "when the atrributes are invalid" do
        let(:attributes) do
          {
            value: 100.10,
            financial_quarter: nil,
            financial_year: nil,
            comment: "Some words",
          }
        end

        it "raises an error with the validation errors" do
          expect { subject }.to raise_error(CreateRefund::Error, /Select a financial year/)
        end

        it "does not create a historical event" do
          subject
        rescue CreateRefund::Error
          expect(history_recorder).to_not have_received(:call)
        end
      end
    end

    context "when there is no editable report for the activity" do
      before do
        allow(Report).to receive(:editable_for_activity) { nil }
      end

      let(:attributes) do
        {
          value: 100.10,
          financial_quarter: 1,
          financial_year: 2020,
          comment: "Some words",
        }
      end

      it "raises an error explaining the problem with the report" do
        expect { subject }.to raise_error(
          CreateRefund::Error,
          /There is no editable report for this activity/
        )
      end

      it "does not create a historical event" do
        subject
      rescue CreateRefund::Error
        expect(history_recorder).to_not have_received(:call)
      end
    end
  end
end
