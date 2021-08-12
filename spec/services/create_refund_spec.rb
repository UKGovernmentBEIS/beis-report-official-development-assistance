require "rails_helper"

RSpec.describe CreateRefund do
  let(:activity) { create(:project_activity) }
  let(:report) { create(:report) }
  let(:creator) { described_class.new(activity: activity) }

  describe "#call" do
    subject { creator.call(attributes: attributes) }
    let(:refund) { subject.object }

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
          expect { subject }.to change { Refund.count }.by(1)
        end

        it "returns a result object" do
          expect(subject).to be_a(Result)
          expect(subject.success?).to eq(true)
          expect(subject.object).to be_a(Refund)
        end

        it "sets the correct attributes" do
          expect(refund.parent_activity).to eq(activity)
          expect(refund.report).to eq(report)
          expect(refund.value).to eq(100.10)
          expect(refund.financial_quarter).to eq(1)
          expect(refund.financial_year).to eq(2020)
          expect(refund.comment).to eq("Some words")
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

        it "does not create a refund" do
          expect { subject }.to_not change { Refund.count }
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

      it "does not create a refund" do
        expect { subject }.to_not change { Refund.count }
      end
    end
  end
end
