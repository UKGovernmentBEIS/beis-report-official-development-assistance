RSpec.describe OrganisationHelper do
  describe "#organisation_page_back_link" do
    let(:organisation) { create(:delivery_partner_organisation) }
    let(:other_organisation) { create(:delivery_partner_organisation) }

    let(:user) { create(:administrator, organisation: organisation) }

    context "the user is on their own organisation's show page" do
      it "does not show a back link" do
        params = {controller: "staff/organisations", action: "show", id: organisation.id}
        expect(helper.organisation_page_back_link(user, params)).to eq(nil)
      end
    end

    context "the user is on another organisation's show page" do
      it "shows a back link to the organisation#index page" do
        params = {controller: "staff/organisations", action: "show", id: other_organisation.id}
        expect(helper.organisation_page_back_link(user, params)).to eq('<a class="govuk-back-link" href="/organisations">Back</a>')
      end
    end

    context "when the user is an administrator" do
      let(:user) { create(:administrator, organisation: organisation) }

      context "the user is on their own organisation's show page" do
        it "does not show a back link" do
          params = {controller: "staff/organisations", action: "show", id: organisation.id}
          expect(helper.organisation_page_back_link(user, params)).to eq(nil)
        end
      end

      context "the user is on another organisation's show page" do
        it "shows a back link to the organisation#index page" do
          params = {controller: "staff/organisations", action: "show", id: other_organisation.id}
          expect(helper.organisation_page_back_link(user, params)).to eq('<a class="govuk-back-link" href="/organisations">Back</a>')
        end
      end
    end
  end
end
