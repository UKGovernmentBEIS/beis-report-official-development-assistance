require "rails_helper"

RSpec.describe Staff::ActivityUploadsController do
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

        expect(response.body).to include(t("action.actual.upload.button"))
      end
    end

    context "with a report awaiting changes" do
      let(:state) { :awaiting_changes }

      it "shows the upload button" do
        get :new, params: {report_id: report.id}

        expect(response.body).to include(t("action.actual.upload.button"))
      end
    end

    context "with a report in review" do
      let(:state) { :in_review }

      it "doesn't show the upload button" do
        get :new, params: {report_id: report.id}

        expect(response.body).to_not include(t("action.actual.upload.button"))
      end
    end
  end

  describe "#update" do
    let(:report) { create(:report, organisation: organisation, state: :active) }
    let(:file_upload) { "file upload double" }
    let(:uploaded_rows) { double("uploaded rows") }
    let(:upload) { instance_double(CsvFileUpload, rows: uploaded_rows, valid?: true) }

    let(:importer) do
      instance_double(
        Activities::ImportFromCsv,
        import: true,
        errors: [],
        created: double,
        updated: double
      )
    end

    before do
      allow(CsvFileUpload).to receive(:new).and_return(upload)
      allow(Activities::ImportFromCsv).to receive(:new).and_return(importer)
    end

    it "asks CsvFileUpload to prepare the uploaded activites" do
      put :update, params: {report_id: report.id, report: file_upload}

      expect(CsvFileUpload).to have_received(:new).with(file_upload, :activity_csv)
    end

    context "when upload is valid" do
      before { allow(upload).to receive(:valid?).and_return(true) }

      it "asks ImportFromCsv to import the uploaded rows" do
        put :update, params: {report_id: report.id, report: file_upload}

        expect(Activities::ImportFromCsv).to have_received(:new).with(
          uploader: user,
          delivery_partner_organisation: organisation,
          report: report
        )

        expect(importer).to have_received(:import).with(uploaded_rows)
      end
    end

    context "when upload is NOT valid" do
      before { allow(upload).to receive(:valid?).and_return(false) }

      it "does NOT ask ImportFromCsv to import the uploaded rows" do
        put :update, params: {report_id: report.id, report: file_upload}

        expect(Activities::ImportFromCsv).not_to have_received(:new)
      end
    end
  end
end
