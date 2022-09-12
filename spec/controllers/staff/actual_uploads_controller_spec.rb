require "rails_helper"

RSpec.describe Staff::ActualUploadsController do
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
end
