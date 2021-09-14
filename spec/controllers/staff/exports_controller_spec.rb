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
          "Content-Type" => "text/csv",
        })
      end

      it "returns a CSV of all of the exports" do
        expect(CSV.parse(response.body.delete_prefix("\uFEFF")).first).to match_array(QuarterlyExternalIncomeExport::HEADERS)
      end
    end
  end
end
