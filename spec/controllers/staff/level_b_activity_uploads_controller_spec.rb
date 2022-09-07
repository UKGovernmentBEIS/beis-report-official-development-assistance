require "rails_helper"

RSpec.describe Staff::LevelBActivityUploadsController do
  let(:organisation) { create(:partner_organisation, beis_organisation_reference: "porg") }
  let(:user) { create(:beis_user) }
  before { authenticate!(user: user) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "#new" do
    render_views

    it "shows the upload button" do
      get :new, params: {organisation_id: organisation.id}

      expect(response.body).to include(t("action.activity.bulk_download.button"))
    end
  end

  describe "#show" do
    it "downloads the CSV template with the correct filename" do
      get :show, params: {organisation_id: organisation.id}

      expect(response.headers.to_h).to include({
        "Content-Type" => "text/csv",
        "Content-Disposition" => "attachment; filename=PORG-Level_B_activities_upload.csv"
      })
    end
  end
end
