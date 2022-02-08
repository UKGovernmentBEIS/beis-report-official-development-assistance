require "rails_helper"

RSpec.describe Staff::OrganisationReportsController do
  describe "#index" do
    let(:organisation) { create(:delivery_partner_organisation) }
    let(:user) { create(:delivery_partner_user, organisation: organisation) }

    before do
      allow(controller).to receive(:current_user).and_return(user)
    end

    it "calls the reports fetcher with the expected organisation" do
      fetcher = double(Report::OrganisationReportsFetcher)
      expect(Report::OrganisationReportsFetcher).to receive(:new).with(organisation: organisation).and_return(fetcher)

      get :index, params: {organisation_id: organisation.id}

      expect(assigns(:reports)).to eq(fetcher)
    end

    context "if the organisation requested does not match the logged in user" do
      let(:other_organisation) { create(:delivery_partner_organisation) }

      it "does not allow the user to view the reports" do
        get :index, params: {organisation_id: other_organisation.id}

        expect(response.code).to eq("401")
      end
    end
  end
end
