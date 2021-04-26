require "rails_helper"

RSpec.describe "Factory" do
  describe "Activity Factory" do
    context "when multiple beis_organisation factories are created" do
      it "only creates 1 record" do
        create_list(:beis_organisation, 2)

        result = Organisation.where(
          name: "Department for Business, Energy and Industrial Strategy",
          iati_reference: Organisation::SERVICE_OWNER_IATI_REFERENCE,
          service_owner: true
        )

        expect(result.count).to eq(1)
      end
    end
  end
end
