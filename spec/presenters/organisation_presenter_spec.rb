# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrganisationPresenter do
  let(:organisation) { FactoryBot.build(:delivery_partner_organisation, language_code: "EN", default_currency: "GBP") }

  describe "#language_code" do
    it "converts to readable form" do
      expect(described_class.new(organisation).language_code).to eq("English")
    end
  end

  describe "#default_currency" do
    it "converts to readable form" do
      expect(described_class.new(organisation).default_currency).to eq("Pound Sterling")
    end
  end
end
