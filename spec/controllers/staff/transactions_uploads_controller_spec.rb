require "rails_helper"

RSpec.describe Staff::TransactionUploadsController do
  let(:user) { create(:delivery_partner_user, organisation: organisation) }
  let(:organisation) { create(:delivery_partner_organisation) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:logged_in_using_omniauth?).and_return(true)
  end

  describe "#show" do
    let(:report) { create(:report, organisation: organisation, state: :active, fund: fund) }

    let!(:fund) { create(:fund_activity, roda_identifier_fragment: "A") }
    let!(:programme_a) { create(:programme_activity, parent: fund, organisation: report.organisation, roda_identifier_fragment: "A", created_at: rand(0..60).minutes.ago) }
    let!(:programme_b) { create(:programme_activity, parent: fund, organisation: report.organisation, roda_identifier_fragment: "B", created_at: rand(0..60).minutes.ago) }
    let!(:project_c) { create(:project_activity, parent: programme_a, organisation: report.organisation, roda_identifier_fragment: "C", created_at: rand(0..60).minutes.ago) }
    let!(:project_d) { create(:project_activity, parent: programme_b, organisation: report.organisation, roda_identifier_fragment: "D", created_at: rand(0..60).minutes.ago) }
    let!(:third_party_project_e) { create(:third_party_project_activity, parent: project_c, organisation: report.organisation, roda_identifier_fragment: "E", created_at: rand(0..60).minutes.ago) }
    let!(:third_party_project_f) { create(:third_party_project_activity, parent: project_c, organisation: report.organisation, roda_identifier_fragment: "F", created_at: rand(0..60).minutes.ago) }

    it "returns activities in a predictable order" do
      get :show, params: {report_id: report.id}

      csv = CSV.parse(response.body, headers: true)

      expect(csv.count).to eq(4)
      expect(csv[0]["Activity RODA Identifier"]).to eq(project_c.roda_identifier_compound)
      expect(csv[1]["Activity RODA Identifier"]).to eq(third_party_project_e.roda_identifier_compound)
      expect(csv[2]["Activity RODA Identifier"]).to eq(third_party_project_f.roda_identifier_compound)
      expect(csv[3]["Activity RODA Identifier"]).to eq(project_d.roda_identifier_compound)
    end
  end
end
