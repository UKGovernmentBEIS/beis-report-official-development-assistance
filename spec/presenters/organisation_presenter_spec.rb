# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrganisationPresenter do
  let(:organisation) { FactoryBot.build(:partner_organisation, beis_organisation_reference: "AMS", language_code: "EN", default_currency: "GBP") }
  subject(:presenter) { OrganisationPresenter.new(organisation) }

  describe "#language_code" do
    it "converts to readable form" do
      expect(presenter.language_code).to eq("English")
    end
  end

  describe "#default_currency" do
    it "converts to readable form" do
      expect(presenter.default_currency).to eq("Pound Sterling")
    end
  end

  describe "#filename_for_activities_template" do
    context "when passed `:ispf_oda`" do
      it "generates the correct filename for the level B activities upload" do
        expect(presenter.filename_for_activities_template(type: :ispf_oda)).to eq("AMS-Level_B_ISPF_ODA_activities_upload.csv")
      end
    end

    context "when passed `:non_ispf`" do
      it "generates the correct filename for the level B activities upload" do
        expect(presenter.filename_for_activities_template(type: :non_ispf)).to eq("AMS-Level_B_GCRF_NF_OODA_activities_upload.csv")
      end
    end
  end
end
