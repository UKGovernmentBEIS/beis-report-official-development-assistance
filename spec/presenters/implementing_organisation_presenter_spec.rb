require "rails_helper"

RSpec.describe ImplementingOrganisationPresenter do
  describe "#organisation_type" do
    it "takes the code and changes it to the name of the organisation type" do
      organisation = Organisation.new(
        name: "This organisation",
        organisation_type: "70",
        iati_reference: "GB-COH-1234566"
      )
      implementing_organisation_presenter = ImplementingOrganisationPresenter.new(organisation)

      expect(implementing_organisation_presenter.organisation_type).to eq "Private Sector"
    end
  end
end
