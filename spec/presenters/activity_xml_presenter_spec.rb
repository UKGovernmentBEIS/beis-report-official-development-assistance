# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActivityXmlPresenter do
  describe "#iati_identifier" do
    context "when the activity is a fund" do
      it "returns a composite identifier formed with the reporting organisation" do
        fund = build(:fund_activity, identifier: "GCRF-1", reporting_organisation_reference: "GB-GOV-13")
        expect(described_class.new(fund).iati_identifier).to eql("GB-GOV-13-GCRF-1")
      end
    end

    context "when the activity is a programme" do
      context "when the reporting organisation is a government organisation" do
        it "returns an identifier with the reporting organisation, fund and programme" do
          government_organisation = build(:organisation, iati_reference: "GB-GOV-13")
          programme = create(:programme_activity, organisation: government_organisation)
          fund = programme.activity

          expect(described_class.new(programme).iati_identifier)
            .to eql("GB-GOV-13-#{fund.identifier}-#{programme.identifier}")
        end
      end
    end

    context "when the activity is a project" do
      context "when the reporting organisation is a government organisation" do
        it "returns an identifier with the reporting organisation, fund, programme and project" do
          government_organisation = build(:organisation, iati_reference: "GB-GOV-13")
          project = create(:project_activity, organisation: government_organisation)
          programme = project.activity
          fund = programme.activity

          expect(described_class.new(project).iati_identifier)
            .to eql("GB-GOV-13-#{fund.identifier}-#{programme.identifier}-#{project.identifier}")
        end
      end
    end
  end
end
