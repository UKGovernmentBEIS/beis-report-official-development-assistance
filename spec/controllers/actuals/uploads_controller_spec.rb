require "rails_helper"

RSpec.describe Actuals::UploadsController do
  let(:user) { create(:partner_organisation_user, organisation: organisation) }
  let(:organisation) { create(:partner_organisation) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  RSpec::Matchers.define :have_upload_button do
    match do |actual|
      RSpec::Matchers::BuiltIn::Match.new("#{t("action.actual.upload.button")}</button>").matches?(actual)
    end
  end

  describe "#new" do
    render_views

    let(:report) { create(:report, organisation: organisation, state: state) }

    context "with an active report" do
      let(:state) { :active }

      it "shows the upload button" do
        get :new, params: {report_id: report.id}

        expect(response.body).to have_upload_button
      end
    end

    context "with a report awaiting changes" do
      let(:state) { :awaiting_changes }

      it "shows the upload button" do
        get :new, params: {report_id: report.id}

        expect(response.body).to have_upload_button
      end
    end

    context "with a report in review" do
      let(:state) { :in_review }
      it "doesn't show the upload button" do
        get :new, params: {report_id: report.id}
        expect(response.body).to_not have_upload_button
      end
    end

    context "as a BEIS user" do
      let(:user) { create(:beis_user) }

      context "with an active report" do
        let(:state) { :active }

        it "doesn't show the upload button" do
          get :new, params: {report_id: report.id}

          expect(response.body).to_not have_upload_button
        end
      end

      context "with a report awaiting changes" do
        let(:state) { :awaiting_changes }

        it "doesn't show the upload button" do
          get :new, params: {report_id: report.id}

          expect(response.body).to_not have_upload_button
        end
      end
    end
  end

  describe "#show" do
    let(:report) { create(:report, :active, organisation: organisation, fund: fund) }

    let!(:fund) { create(:fund_activity, roda_identifier: "A") }
    let!(:programme_a) { create(:programme_activity, parent: fund, roda_identifier: "A-A", created_at: rand(0..60).minutes.ago) }
    let!(:programme_b) { create(:programme_activity, parent: fund, roda_identifier: "A-B", created_at: rand(0..60).minutes.ago) }
    let!(:project_c) { create(:project_activity, parent: programme_a, organisation: report.organisation, roda_identifier: "A-A-C", created_at: rand(0..60).minutes.ago) }
    let!(:project_d) { create(:project_activity, parent: programme_b, organisation: report.organisation, roda_identifier: "A-B-D", created_at: rand(0..60).minutes.ago) }
    let!(:third_party_project_e) { create(:third_party_project_activity, parent: project_c, organisation: report.organisation, roda_identifier: "A-A-C-E", created_at: rand(0..60).minutes.ago) }
    let!(:third_party_project_f) { create(:third_party_project_activity, parent: project_c, organisation: report.organisation, roda_identifier: "A-B-D-F", created_at: rand(0..60).minutes.ago) }

    let!(:stopped_project) { create(:project_activity, parent: programme_a, organisation: report.organisation, programme_status: "stopped") }
    let!(:cancelled_project) { create(:project_activity, parent: programme_b, organisation: report.organisation, programme_status: "cancelled") }
    let!(:completed_project) { create(:project_activity, parent: programme_a, organisation: report.organisation, programme_status: "completed") }
    let!(:paused_project) { create(:project_activity, parent: programme_b, organisation: report.organisation, programme_status: "paused") }
    let!(:ineligible_project) { create(:project_activity, parent: programme_b, organisation: report.organisation, oda_eligibility: 2) }

    it "returns activities in a predictable order" do
      get :show, params: {report_id: report.id}

      csv = CSV.parse(response.body, headers: true)

      expect(csv.count).to eq(4)
      expect(csv[0]["Activity RODA Identifier"]).to eq(project_c.roda_identifier)
      expect(csv[1]["Activity RODA Identifier"]).to eq(third_party_project_e.roda_identifier)
      expect(csv[2]["Activity RODA Identifier"]).to eq(third_party_project_f.roda_identifier)
      expect(csv[3]["Activity RODA Identifier"]).to eq(project_d.roda_identifier)
    end

    it "does not include non-reportable activities" do
      get :show, params: {report_id: report.id}

      csv = CSV.parse(response.body, headers: true)

      roda_identifiers = csv.pluck("Activity RODA Identifier")

      expect(roda_identifiers).to_not include(stopped_project.roda_identifier)
      expect(roda_identifiers).to_not include(cancelled_project.roda_identifier)
      expect(roda_identifiers).to_not include(completed_project.roda_identifier)
      expect(roda_identifiers).to_not include(paused_project.roda_identifier)
      expect(roda_identifiers).to_not include(ineligible_project.roda_identifier)
    end
  end

  describe "#update" do
    let(:report) { create(:report, organisation: organisation, state: :active) }

    context "the use new importer feature flag is false" do
      before { allow(ROLLOUT).to receive(:active?).with(:use_new_activity_actual_refund_comment_importer).and_return(false) }

      it "uses the original actuals importer" do
        fake_import_file = instance_double(CsvFileUpload)
        allow(fake_import_file).to receive(:rows).and_return([])
        allow(fake_import_file).to receive(:valid?).and_return(true)
        allow(CsvFileUpload).to receive(:new).and_return(fake_import_file)

        importer = instance_double(Actual::Import)
        allow(importer).to receive(:import).and_return(true)
        allow(importer).to receive(:errors).and_return([])
        allow(importer).to receive(:imported_actuals).and_return([])
        allow(importer).to receive(:invalid_with_comment).and_return(false)
        allow(Actual::Import).to receive(:new).and_return(importer)

        allow(Import::Csv::ActivityActualRefundComment::FileService).to receive(:new)

        patch :update, params: {report_id: report.id}

        expect(importer).to have_received(:import)
        expect(Import::Csv::ActivityActualRefundComment::FileService).not_to have_received(:new)
      end
    end

    context "the use new importer feature flag is true" do
      before { allow(ROLLOUT).to receive(:active?).with(:use_new_activity_actual_refund_comment_importer).and_return(true) }

      it "uses the new file importer" do
        fake_import_file = instance_double(CsvFileUpload)
        allow(fake_import_file).to receive(:rows).and_return([])
        allow(fake_import_file).to receive(:valid?).and_return(true)
        allow(CsvFileUpload).to receive(:new).and_return(fake_import_file)

        importer = instance_double(Import::Csv::ActivityActualRefundComment::FileService)
        allow(importer).to receive(:import!).and_return(true)
        allow(importer).to receive(:errors).and_return([])
        allow(importer).to receive(:imported_actuals).and_return([])
        allow(importer).to receive(:imported_refunds).and_return([])
        allow(importer).to receive(:imported_comments).and_return([])
        allow(importer).to receive(:skipped_rows).and_return([])
        allow(Import::Csv::ActivityActualRefundComment::FileService).to receive(:new).and_return(importer)

        allow(Actual::Import).to receive(:new)

        patch :update, params: {report_id: report.id}

        expect(importer).to have_received(:import!)
        expect(Actual::Import).not_to have_received(:new)
      end
    end
  end
end
