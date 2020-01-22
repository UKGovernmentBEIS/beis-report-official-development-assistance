# TODO: This data will eventually need to be public so that IATI can retrieve it
RSpec.feature "Fund managers can view a fund as XML" do
  context "when the user belongs to the organisation the fund is part of" do
    it "returns an XML response" do
      organisation = create(:organisation)
      fund = create(:fund, organisation: organisation, identifier: "IND-ENT-IFIER")
      transaction = create(:transaction, fund: fund)
      authenticate!(user: build_stubbed(:fund_manager, organisations: [organisation]))

      visit organisation_fund_path(organisation, fund, format: :xml)

      xml = Nokogiri::XML::Document.parse(page.body)

      # The activity XML is present
      expect(xml.at("iati-activity/@default-currency").text).to eq(fund.default_currency)
      expect(xml.at("iati-activity/iati-identifier").text).to eq(fund.identifier)

      # The transaction XML is present
      expect(xml.at("iati-activity/transaction/@ref").text).to eq(transaction.reference)
    end
  end
end
