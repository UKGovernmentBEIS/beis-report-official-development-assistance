require "rails_helper"

RSpec.describe LevelB::Activities::UploadsController do
  let(:organisation) { create(:partner_organisation, beis_organisation_reference: "porg") }
  let(:user) { create(:beis_user) }

  before { authenticate!(user: user) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  after { logout }

  describe "#new" do
    render_views

    it "shows the download links" do
      get :new, params: {organisation_id: organisation.id}

      expect(response.body).to include(t("action.activity.download.link", type: t("action.activity.type.ispf_oda")))
      expect(response.body).to include(t("action.activity.download.link", type: t("action.activity.type.non_ispf")))
    end

    context "when signed in as a partner organisation user" do
      let(:user) { create(:partner_organisation_user) }

      it "responds with a 401" do
        get :new, params: {organisation_id: organisation.id}

        expect(response.status).to eq(401)
      end
    end
  end

  describe "#show" do
    context "when requesting the ISPF ODA template" do
      it "downloads the CSV template with the correct filename" do
        get :show, params: {organisation_id: organisation.id, type: :ispf_oda}

        expect(response.headers.to_h).to include({
          "Content-Type" => "text/csv",
          "Content-Disposition" => "attachment; filename=PORG-Level_B_ISPF_ODA_activities_upload.csv"
        })
      end
    end

    context "when requesting the non-ISPF template" do
      it "downloads the CSV template with the correct filename" do
        get :show, params: {organisation_id: organisation.id, type: :non_ispf}

        expect(response.headers.to_h).to include({
          "Content-Type" => "text/csv",
          "Content-Disposition" => "attachment; filename=PORG-Level_B_GCRF_NF_OODA_activities_upload.csv"
        })
      end
    end
  end

  describe "#update" do
    let(:file_upload) { "file upload double" }
    let(:uploaded_rows) { double("uploaded rows") }
    let(:upload) { instance_double(CsvFileUpload, rows: uploaded_rows, valid?: true) }

    let(:importer) do
      instance_double(
        Activity::Import,
        import: true,
        errors: [],
        created: double,
        updated: double
      )
    end

    before do
      allow(CsvFileUpload).to receive(:new).and_return(upload)
      allow(Activity::Import).to receive(:new).and_return(importer)
    end

    it "asks CsvFileUpload to prepare the uploaded activities" do
      put :update, params: {organisation_id: organisation.id, organisation: file_upload}

      expect(CsvFileUpload).to have_received(:new).with(file_upload, :activity_csv)
    end

    context "when upload is valid" do
      before { allow(upload).to receive(:valid?).and_return(true) }

      it "asks Activity::Import to import the uploaded rows" do
        put :update, params: {organisation_id: organisation.id, organisation: file_upload}

        expect(Activity::Import).to have_received(:new).with(
          uploader: user,
          partner_organisation: organisation,
          report: nil
        )

        expect(importer).to have_received(:import).with(uploaded_rows)
      end
    end

    context "when upload is NOT valid" do
      before { allow(upload).to receive(:valid?).and_return(false) }

      it "does NOT ask Activity::Import to import the uploaded rows" do
        put :update, params: {organisation_id: organisation.id, organisation: file_upload}

        expect(Activity::Import).not_to have_received(:new)
      end
    end
  end
end
