require "rails_helper"

RSpec.describe Staff::ReportsController do
  describe "#index" do
    context "when logged in as a delivery partner" do
      let(:organisation) { create(:delivery_partner_organisation) }
      let(:user) { create(:delivery_partner_user, organisation: organisation) }

      before do
        allow(controller).to receive(:current_user).and_return(user)
        allow(controller).to receive(:logged_in_using_omniauth?).and_return(true)
      end

      it "redirects to show the user's organisation's reports" do
        expect(get(:index)).to redirect_to(organisation_reports_path(organisation_id: organisation.id))
      end
    end
  end
end
