require "rails_helper"

RSpec.describe RemoveBeisReports do
  let(:beis) { create(:beis_organisation) }
  let(:delivery_partner) { create(:delivery_partner_organisation) }

  let(:fund) { programme.parent }
  let(:programme) { create(:programme_activity, organisation: beis) }
  let(:project) { create(:project_activity, organisation: delivery_partner, parent: programme) }

  context "when there are reports for the service owner" do
    let!(:approved_report) { create(:report, fund: fund, organisation: beis, financial_year: 2020, financial_quarter: 2, state: :approved) }
    let!(:active_report) { create(:report, fund: fund, organisation: beis, financial_year: 2020, financial_quarter: 3, state: :active) }

    it "deletes all the reports" do
      RemoveBeisReports.execute
      expect(Report.count).to eq(0)
    end
  end

  context "when there are reports for the service owner and delivery partner" do
    let!(:beis_approved_report) { create(:report, fund: fund, organisation: beis, financial_year: 2020, financial_quarter: 2, state: :approved) }
    let!(:beis_active_report) { create(:report, fund: fund, organisation: beis, financial_year: 2020, financial_quarter: 3, state: :active) }
    let!(:dp_active_report) { create(:report, fund: fund, organisation: delivery_partner, financial_year: 2020, financial_quarter: 3, state: :active) }

    it "deletes only the service owner's reports" do
      RemoveBeisReports.execute
      expect(Report.count).to eq(1)
      expect(Report.all.map(&:organisation)).to eq [delivery_partner]
    end

    context "with level A/B transactions in service owner reports" do
      let!(:beis_approved_txn) { create(:transaction, parent_activity: programme, report: beis_approved_report) }
      let!(:beis_active_txn) { create(:transaction, parent_activity: programme, report: beis_active_report) }

      it "retains all the transactions" do
        RemoveBeisReports.execute
        expect(Transaction.count).to eq(2)
      end

      it "unlinks these transactions from their report" do
        RemoveBeisReports.execute
        expect(Transaction.where.not(report_id: nil).count).to eq(0)
      end
    end

    context "with level A/B transactions in delivery partner reports" do
      let!(:dp_active_txn) { create(:transaction, parent_activity: programme, report: dp_active_report) }

      it "retains all the transactions" do
        RemoveBeisReports.execute
        expect(Transaction.count).to eq(1)
      end

      it "unlinks these transactions from their report" do
        RemoveBeisReports.execute
        expect(Transaction.all.map(&:report)).to eq [nil]
      end
    end

    context "with level C/D transactions in delivery partner reports" do
      let!(:dp_active_txn) { create(:transaction, parent_activity: project, report: dp_active_report) }

      it "retains all the transactions" do
        RemoveBeisReports.execute
        expect(Transaction.count).to eq(1)
      end

      it "leaves these transactions linked to their reports" do
        RemoveBeisReports.execute
        expect(Transaction.all.map(&:report)).to eq [dp_active_report]
      end
    end
  end
end
