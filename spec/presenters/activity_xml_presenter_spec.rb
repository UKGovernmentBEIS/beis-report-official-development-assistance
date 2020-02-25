# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActivityXmlPresenter do
  describe "#iati_identifier" do
    it "returns a composite identifier formed with the reporting organisation" do
      fund = build(:fund_activity, identifier: "GCRF-1", reporting_organisation_reference: "GB-GOV-13")
      expect(described_class.new(fund).iati_identifier).to eql("GB-GOV-13-GCRF-1")
    end
    end
  end
end
