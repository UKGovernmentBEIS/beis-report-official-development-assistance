require "rails_helper"

RSpec.describe Report::GroupedReportsFetcher do
  let(:organisation1) { build(:partner_organisation) }
  let(:organisation2) { build(:partner_organisation) }
  let(:subject) { described_class.new }

  describe "#approved" do
    it "returns approved reports grouped by organisation and sorted by organisation name" do
      organisation1_approved_reports = build_list(:report, 3, organisation: organisation1)
      organisation2_approved_reports = build_list(:report, 2, organisation: organisation2)

      approved_reports = organisation1_approved_reports + organisation2_approved_reports
      approved_relation_double = double(ActiveRecord::Relation, "[]": approved_reports)

      expect(Report).to receive(:approved).and_return(approved_relation_double)
      expect(approved_relation_double).to receive(:includes).with([:organisation, :fund]).and_return(approved_relation_double)
      expect(approved_relation_double).to receive(:order).with("organisations.name ASC, financial_year, financial_quarter DESC").and_return(approved_reports)

      expect(subject.approved).to eq({
        organisation1 => organisation1_approved_reports,
        organisation2 => organisation2_approved_reports
      })
    end
  end

  describe "#current" do
    it "returns unapproved reports grouped by organisation and sorted by organisation name" do
      organisation1_unapproved_reports = build_list(:report, 2, organisation: organisation1)
      organisation2_unapproved_reports = build_list(:report, 5, organisation: organisation2)

      unapproved_reports = organisation1_unapproved_reports + organisation2_unapproved_reports
      unapproved_relation_double = double(ActiveRecord::Relation, "[]": unapproved_reports)

      expect(Report).to receive(:not_approved).and_return(unapproved_relation_double)
      expect(unapproved_relation_double).to receive(:includes).with([:organisation, :fund]).and_return(unapproved_relation_double)
      expect(unapproved_relation_double).to receive(:order).with("organisations.name ASC, financial_year, financial_quarter DESC").and_return(unapproved_reports)

      expect(subject.current).to eq({
        organisation1 => organisation1_unapproved_reports,
        organisation2 => organisation2_unapproved_reports
      })
    end
  end
end
