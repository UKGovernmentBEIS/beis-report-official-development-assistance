# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrganisationPresenter do
  let(:organisation) { FactoryBot.build(:delivery_partner_organisation, language_code: "EN", default_currency: "GBP") }

  describe "#language_code" do
    it "downcases the language_code" do
      expect(described_class.new(organisation).language_code).to eq("en")
    end
  end

  describe "#default_currency" do
    it "downcases the default_currency" do
      expect(described_class.new(organisation).default_currency).to eq("gbp")
    end
  end
end
