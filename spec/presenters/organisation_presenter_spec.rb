# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrganisationPresenter do
  let(:organisation) { FactoryBot.build(:partner_organisation, language_code: "EN", default_currency: "GBP") }
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
end
