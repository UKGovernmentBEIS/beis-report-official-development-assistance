require "rails_helper"

RSpec.describe Staff::LevelB::Budgets::UploadsController do
  let(:user) { create(:beis_user) }
  before { authenticate!(user: user) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "#new" do
    render_views

    it "shows the upload button" do
      get :new

      expect(response.body).to include(t("action.budget.bulk_download.button"))
    end
  end

  describe "#show" do
    it "downloads the CSV template with the correct filename" do
      get :show

      expect(response.headers.to_h).to include({
        "Content-Type" => "text/csv",
        "Content-Disposition" => "attachment; filename=Level_B_budgets_upload.csv"
      })
    end
  end
end
