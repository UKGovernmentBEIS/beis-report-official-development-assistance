RSpec.describe Staff::Uploads::ActualHistoriesController do
  let(:report) { create(:report, organisation: user.organisation) }

  context "as a BEIS partner user" do
    let(:user) { create(:beis_user) }

    before do
      allow(controller).to receive(:current_user).and_return(user)
    end

    describe "#new" do
      it "renders the view" do
        get :new, params: {report_id: report.id}

        expect(response).to render_template(:new)
      end
    end

    describe "#update" do
      it "renders the new view" do
        put :update, params: {report_id: report.id, actual_csv_file: {}}

        expect(response).to render_template(:new)
      end

      it "handles a missing file with an error" do
        put :update, params: {report_id: report.id}

        expect(response).to render_template(:new)
        expect(flash[:error]).to eq(t("actions.uploads.actual_histories.missing"))
      end

      it "handles an invalid file with an error" do
        upload = double(CsvFileUpload, valid?: false)
        allow(CsvFileUpload).to receive(:new).and_return(upload)
        allow(controller).to receive(:file_supplied?).and_return(true)

        put :update, params: {report_id: report.id}

        expect(response).to render_template(:new)

        expect(flash[:error]).to eq(t("actions.uploads.actual_histories.invalid"))
      end
    end
  end

  context "as a partner organisation user" do
    let(:user) { create(:partner_organisation_user) }

    before do
      allow(controller).to receive(:current_user).and_return(user)
    end

    describe "#new" do
      it "returns unauthorized (401)" do
        get :new, params: {report_id: report.id}

        expect(response).to have_http_status(:unauthorized)
      end
    end

    describe "#update" do
      it "returns unauthorized (401)" do
        put :update, params: {report_id: report.id}

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
