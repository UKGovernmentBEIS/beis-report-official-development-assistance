require "rails_helper"

RSpec.describe Staff::ForecastUploadsController do
  let(:user) { create(:delivery_partner_user, organisation: organisation) }
  let(:organisation) { create(:delivery_partner_organisation) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:logged_in_using_omniauth?).and_return(true)
  end

  describe "#new" do
    render_views

    let(:report) { create(:report, organisation: organisation, state: state) }

    context "with an active report" do
      let(:state) { :active }

      it "shows the upload button" do
        get :new, params: {report_id: report.id}

        expect(response.body).to include(t("action.transaction.upload.button"))
      end
    end

    context "with a report awaiting changes" do
      let(:state) { :awaiting_changes }

      it "shows the upload button" do
        get :new, params: {report_id: report.id}

        expect(response.body).to include(t("action.transaction.upload.button"))
      end
    end

    context "with a report in review" do
      let(:state) { :in_review }

      it "doesn't show the upload button" do
        get :new, params: {report_id: report.id}

        expect(response.body).to_not include(t("action.transaction.upload.button"))
      end
    end
  end
end
