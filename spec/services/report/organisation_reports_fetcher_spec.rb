require "rails_helper"

RSpec.describe Report::OrganisationReportsFetcher do
  let(:organisation) { build(:partner_organisation) }

  let(:fetcher) { described_class.new(organisation: organisation) }

  describe "#approved" do
    subject { fetcher.approved }

    it "returns approved reports for an organisation" do
      approved_reports = build_list(:report, 3, :approved, organisation: organisation)

      approved_relation_double = double(ActiveRecord::Relation, "[]": approved_reports)

      expect(Report).to receive(:where).with(organisation: organisation).and_return(approved_relation_double)
      expect(approved_relation_double).to receive(:approved).and_return(approved_relation_double)

      expect(approved_relation_double).to receive(:includes).with([:organisation, :fund]).and_return(approved_relation_double)
      expect(approved_relation_double).to receive(:order).with("financial_year, financial_quarter DESC").and_return(approved_reports)

      expect(subject).to eq(approved_reports)
    end

    context "when the feature flag hiding ISPF is enabled for partner organisation users" do
      before do
        feature = double(:feature, groups: [:partner_organisation_users])
        allow(ROLLOUT).to receive(:get).with(:ispf_fund_in_stealth_mode).and_return(feature)
      end

      it "only returns approved non-ISPF reports" do
        non_ispf_approved_reports = build_list(:report, 3, :approved, organisation: organisation)

        non_ispf_approved_relation_double = double(ActiveRecord::Relation, "[]": non_ispf_approved_reports)

        expect(Report).to receive(:where).with(organisation: organisation).and_return(non_ispf_approved_relation_double)
        expect(non_ispf_approved_relation_double).to receive_message_chain(:not_ispf, :approved).and_return(non_ispf_approved_relation_double)

        expect(non_ispf_approved_relation_double).to receive(:includes).with([:organisation, :fund]).and_return(non_ispf_approved_relation_double)
        expect(non_ispf_approved_relation_double).to receive(:order).with("financial_year, financial_quarter DESC").and_return(non_ispf_approved_reports)

        expect(subject).to eq(non_ispf_approved_reports)
      end
    end
  end

  describe "#current" do
    subject { fetcher.current }

    it "returns active unapproved reports for an organisation" do
      unapproved_reports = build_list(:report, 2, :active, organisation: organisation)

      unapproved_relation_double = double(ActiveRecord::Relation, "[]": unapproved_reports)

      expect(Report).to receive(:where).with(organisation: organisation).and_return(unapproved_relation_double)
      expect(unapproved_relation_double).to receive(:not_approved).and_return(unapproved_relation_double)

      expect(unapproved_relation_double).to receive(:includes).with([:organisation, :fund]).and_return(unapproved_relation_double)
      expect(unapproved_relation_double).to receive(:order).with("financial_year, financial_quarter DESC").and_return(unapproved_reports)

      expect(subject).to eq(unapproved_reports)
    end

    context "when the feature flag hiding ISPF is enabled for partner organisation users" do
      before do
        feature = double(:feature, groups: [:partner_organisation_users])
        allow(ROLLOUT).to receive(:get).with(:ispf_fund_in_stealth_mode).and_return(feature)
      end

      it "only returns active unapproved non-ISPF reports for the organisation" do
        non_ispf_unapproved_reports = build_list(:report, 2, :active, organisation: organisation)

        non_ispf_unapproved_relation_double = double(ActiveRecord::Relation, "[]": non_ispf_unapproved_reports)

        expect(Report).to receive(:where).with(organisation: organisation).and_return(non_ispf_unapproved_relation_double)
        expect(non_ispf_unapproved_relation_double).to receive_message_chain(:not_ispf, :not_approved).and_return(non_ispf_unapproved_relation_double)

        expect(non_ispf_unapproved_relation_double).to receive(:includes).with([:organisation, :fund]).and_return(non_ispf_unapproved_relation_double)
        expect(non_ispf_unapproved_relation_double).to receive(:order).with("financial_year, financial_quarter DESC").and_return(non_ispf_unapproved_reports)

        expect(subject).to eq(non_ispf_unapproved_reports)
      end
    end
  end
end
