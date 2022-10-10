require "rails_helper"

RSpec.describe LevelB::Budgets::UploadsController do
  let(:user) { create(:beis_user) }

  before { authenticate!(user: user) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  after { logout }

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

  describe "#create" do
    let(:file_upload) { "file upload double" }
    let(:uploaded_rows) { double("uploaded rows") }
    let(:upload) { instance_double(CsvFileUpload, rows: uploaded_rows, valid?: true) }

    let(:importer) do
      instance_double(
        Budget::Import,
        import: true,
        errors: [],
        created: double
      )
    end

    before do
      allow(CsvFileUpload).to receive(:new).and_return(upload)
      allow(Budget::Import).to receive(:new).and_return(importer)
    end

    it "asks CsvFileUpload to prepare the uploaded budgets" do
      put :create, params: {budget_upload: file_upload}

      expect(CsvFileUpload).to have_received(:new).with(file_upload, :csv)
    end

    context "when upload is valid" do
      before { allow(upload).to receive(:valid?).and_return(true) }

      it "asks Budget::Import to import the uploaded rows" do
        put :create, params: {budget_upload: file_upload}

        expect(Budget::Import).to have_received(:new).with(
          uploader: user
        )

        expect(importer).to have_received(:import).with(uploaded_rows)
      end
    end

    context "when upload is NOT valid" do
      before { allow(upload).to receive(:valid?).and_return(false) }

      it "does NOT ask Budget::Import to import the uploaded rows" do
        put :create, params: {budget_upload: file_upload}

        expect(Budget::Import).not_to have_received(:new)
      end
    end
  end
end
