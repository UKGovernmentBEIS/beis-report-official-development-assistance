require "rails_helper"

RSpec.describe BudgetRevisionsHelper, type: :helper do
  describe "#link_to_revisions" do
    let(:budget) { create(:budget) }
    let(:path) { activity_budget_revisions_path(budget.parent_activity_id, budget) }

    subject { helper.link_to_revisions(budget) }

    context "when the Budget has only 1 audit (the original Budget)" do
      it "returns 'None'" do
        expect(subject).to eq "None"
      end
    end

    context "when the Budget has 1 update audit" do
      let(:budget) { create(:budget, :with_revisions) }

      it "returns the number of update audits as a link" do
        expect(subject).to eq link_to("1 revision", path, class: "govuk-link")
      end
    end

    context "when the Budget has more than 1 update audit" do
      let(:budget) { create(:budget, :with_revisions, number_of_revisions: 2) }

      it "returns the number of update audits as a pluralized link" do
        expect(subject).to eq link_to("2 revisions", path, class: "govuk-link")
      end
    end
  end

  describe "#row_header" do
    let(:budget) { create(:budget) }
    let(:audit) { budget.audits.last }

    subject { helper.row_header(audit) }

    context "when the audit is a 'create' audit" do
      it "returns 'Original'" do
        expect(subject).to eq "Original"
      end
    end

    context "when the audit is an 'update' audit" do
      let(:budget) { create(:budget, :with_revisions) }

      it "returns the revision number" do
        expect(subject).to eq "Revision 1"
      end
    end
  end

  describe "#difference" do
    let(:budget) { create(:budget, value: 50) }
    let(:earlier_audit) { budget.audits.first }
    let(:later_audit) { budget.audits.last }

    subject { helper.difference(earlier_audit: earlier_audit, later_audit: later_audit) }

    context "when the earlier audit is nil" do
      let(:earlier_audit) { nil }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when the later audit is a greater value" do
      before { budget.update(value: 100) }

      it "returns the difference between the two revisions as currency with a positive sign" do
        expect(subject).to eq "+£50.00"
      end
    end

    context "when the later audit is a lesser value" do
      before { budget.update(value: 25) }

      it "returns the difference between the two revisions as currency with a negative sign" do
        expect(subject).to eq "-£25.00"
      end
    end
  end
end
