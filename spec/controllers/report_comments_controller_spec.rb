require "rails_helper"

RSpec.describe ReportCommentsController do
  describe "show" do
    let(:report) { build(:report, id: SecureRandom.uuid) }

    before do
      allow(controller).to receive(:current_user).and_return(user)

      allow(Report).to receive(:find).with(report.id).and_return(report)

      get "show", params: {report_id: report.id}
    end

    context "when signed in as a BEIS user" do
      let(:user) { create(:beis_user) }

      it "responds with status 200 OK" do
        expect(response).to have_http_status(:ok)
      end
    end

    context "when signed in as a partner organisation user" do
      let(:user) { create(:partner_organisation_user) }

      context "when the report belongs to the user's organisation" do
        let(:report) { build(:report, :active, id: SecureRandom.uuid, organisation: user.organisation) }

        it "responds with status 200 OK" do
          expect(response).to have_http_status(:ok)
        end
      end

      context "when the report does not belong to the user's organisation" do
        let(:report) { build(:report, id: SecureRandom.uuid) }

        it "responds with status 401 Unauthorized" do
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end
end
