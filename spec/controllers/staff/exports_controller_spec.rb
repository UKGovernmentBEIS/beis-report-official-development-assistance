require "rails_helper"

RSpec.describe Staff::ExportsController do
  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:logged_in_using_omniauth?).and_return(true)
  end

  let(:fund) { Fund.by_short_name("NF") }

  describe "#external_income" do
    before do
      get "external_income", params: {fund_id: fund.id, format: :csv}
    end

    context "when logged in as a delivery partner" do
      let(:user) { create(:delivery_partner_user) }

      it "does not allow the user to access the report" do
        expect(response.status).to eq(401)
      end
    end

    context "when logged in as a BEIS user" do
      let(:user) { create(:beis_user) }

      it "responds with a 200" do
        expect(response.status).to eq(200)
      end

      it "sets the CSV headers correctly" do
        expect(response.headers.to_h).to include({
          "Content-Type" => "text/csv"
        })
      end

      it "returns a CSV of all of the exports" do
        expect(CSV.parse(response.body.delete_prefix("\uFEFF")).first).to match_array(ExternalIncome::Export::HEADERS)
      end
    end
  end

  describe "#budgets" do
    before do
      get "budgets", params: {fund_id: fund.id, format: :csv}
    end

    context "when logged in as a delivery partner" do
      let(:user) { create(:delivery_partner_user) }

      it "does not allow the user to access the report" do
        expect(response.status).to eq(401)
      end
    end

    context "when logged in as a BEIS user" do
      let(:user) { create(:beis_user) }

      it "responds with a 200" do
        expect(response.status).to eq(200)
      end

      it "sets the CSV headers correctly" do
        expect(response.headers.to_h).to include({
          "Content-Type" => "text/csv"
        })
      end

      it "returns a CSV of all of the exports" do
        expect(CSV.parse(response.body.delete_prefix("\uFEFF")).first).to match_array(Budget::Export::HEADERS)
      end
    end
  end

  describe "#spending_breakdown", wip: true do
    render_views
    let(:user) { create(:beis_user) }

    before do
      allow(SpendingBreakdownJob).to receive(:perform_later)
    end

    it "kicks off async job to create the CSV, upload to S3 & email download link" do
      get "spending_breakdown", params: {fund_id: fund.id}

      expect(SpendingBreakdownJob).to have_received(:perform_later).with(
        requester_id: user.id,
        fund_id: fund.id.to_s
      )
    end

    it "responds with the 'export_in_progress' template" do
      get "spending_breakdown", params: {fund_id: fund.id}

      expect(response).to render_template(:export_in_progress)
    end
  end
end
