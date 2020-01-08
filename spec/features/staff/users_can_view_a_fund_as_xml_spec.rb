RSpec.feature "Users can view a fund as XML" do
  before do
    authenticate!(user: user)
  end

  let(:organisation) { create(:organisation) }
  let(:fund) { create(:fund, organisation: organisation) }
  let!(:activity) { create(:activity, hierarchy: fund) }
  let!(:transaction) { create(:transaction, hierarchy: fund) }
  let(:user) { create(:user, organisations: [organisation]) }

  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      page.set_rack_session(userinfo: nil)
      visit organisation_fund_path(organisation, fund)
      expect(current_path).to eq(root_path)
    end
  end

  context "when the user belongs to the organisation the fund is part of" do
    it "returns an XML response" do
      visit organisation_fund_path(organisation, fund, format: :xml)

      xml = Nokogiri::XML::Document.parse(page.body)

      # The activity XML is present
      expect(xml.at("iati-activity/@default-currency").text).to eq(activity.default_currency)
      expect(xml.at("iati-activity/iati-identifier").text).to eq(activity.identifier)

      # The transaction XML is present
      expect(xml.at("iati-activity/transaction/@ref").text).to eq(transaction.reference)
    end
  end
end
