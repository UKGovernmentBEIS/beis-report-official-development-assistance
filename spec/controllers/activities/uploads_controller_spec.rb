require "rails_helper"

RSpec.describe Activities::UploadsController do
  let(:user) { create(:partner_organisation_user, organisation: organisation) }
  let(:organisation) { create(:partner_organisation, beis_organisation_reference: "porg") }
  let(:report) {
    create(
      :report,
      fund: create(:fund_activity, :gcrf),
      organisation: organisation,
      financial_year: 2022,
      financial_quarter: 2
    )
  }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "#new" do
    render_views

    let(:report) { create(:report, organisation: organisation, state: state) }

    context "with an active report" do
      let(:state) { :active }

      it "shows the upload button" do
        get :new, params: {report_id: report.id}

        expect(response.body).to include(t("action.activity.upload.button"))
      end
    end

    context "with a report awaiting changes" do
      let(:state) { :awaiting_changes }

      it "shows the upload button" do
        get :new, params: {report_id: report.id}

        expect(response.body).to include(t("action.activity.upload.button"))
      end
    end

    context "with a report in review" do
      let(:state) { :in_review }

      it "doesn't show the upload button" do
        get :new, params: {report_id: report.id}

        expect(response.body).to_not include(t("action.activity.upload.button"))
      end
    end
  end

  describe "#show" do
    context "when requesting the non-ISPF template" do
      it "downloads the CSV template with the correct filename" do
        get :show, params: {report_id: report.id, type: :non_ispf}

        expect(response.headers.to_h).to include({
          "Content-Type" => "text/csv",
          "Content-Disposition" => "attachment; filename=FQ2%202022-2023-GCRF-PORG-activities_upload.csv"
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
      put :update, params: {report_id: report.id, report: file_upload, type: "non_ispf"}

      expect(CsvFileUpload).to have_received(:new).with(file_upload, :activity_csv)
    end

    context "when upload is valid" do
      before { allow(upload).to receive(:valid?).and_return(true) }

      it "asks Activity::Import to import the uploaded rows" do
        put :update, params: {report_id: report.id, report: file_upload, type: "non_ispf"}

        expect(Activity::Import).to have_received(:new).with(
          uploader: user,
          partner_organisation: organisation,
          report: report,
          is_oda: nil
        )

        expect(importer).to have_received(:import).with(uploaded_rows)
      end
    end

    context "when upload is NOT valid" do
      before { allow(upload).to receive(:valid?).and_return(false) }

      it "does NOT ask Activity::Import to import the uploaded rows" do
        put :update, params: {report_id: report.id, report: file_upload, type: "non_ispf"}

        expect(Activity::Import).not_to have_received(:new)
      end
    end
  end
end
