require "rails_helper"

RSpec.describe Staff::ReportCommentsController do
  describe "show" do
    let(:report) { build(:report, id: SecureRandom.uuid) }

    before do
      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:logged_in_using_omniauth?).and_return(true)

      allow(Report).to receive(:find).with(report.id).and_return(report)

      get "show", params: {report_id: report.id}
    end

    context "when signed in as a BEIS user" do
      let(:user) { create(:beis_user) }

      it "responds with a 200" do
        expect(response.status).to eq(200)
      end
    end

    context "when signed in as a delivery partner" do
      let(:user) { create(:delivery_partner_user) }

      context "when the report belongs to the user's organisation" do
        let(:report) { build(:report, :active, id: SecureRandom.uuid, organisation: user.organisation) }

        it "responds with a 200" do
          expect(response.status).to eq(200)
        end

        context "when the report is inactive" do
          let(:report) { build(:report, :inactive, id: SecureRandom.uuid, organisation: user.organisation) }

          it "responds with a 401" do
            expect(response.status).to eq(401)
          end
        end
      end

      context "when the report does not belong to the user's organisation" do
        let(:report) { build(:report, id: SecureRandom.uuid) }

        it "responds with a 401" do
          expect(response.status).to eq(401)
        end
      end
    end
  end
end
