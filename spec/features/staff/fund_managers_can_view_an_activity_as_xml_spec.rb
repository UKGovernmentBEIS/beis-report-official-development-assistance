# TODO: This data will eventually need to be public so that IATI can retrieve it
RSpec.feature "Fund managers can view an activity as XML" do
  context "when the user belongs to the organisation the activity is part of" do
    it "returns an XML response" do
      organisation = create(:organisation)
      activity = create(:activity, organisation: organisation, identifier: "IND-ENT-IFIER")
      transaction = create(:transaction, activity: activity)
      authenticate!(user: build_stubbed(:fund_manager, organisations: [organisation]))

      visit organisation_activity_path(organisation, activity, format: :xml)

      xml = Nokogiri::XML::Document.parse(page.body)

      # The activity XML is present
      expect(xml.at("iati-activity/@default-currency").text).to eq(activity.default_currency)
      expect(xml.at("iati-activity/iati-identifier").text).to eq(activity.identifier)

      # The transaction XML is present
      expect(xml.at("iati-activity/transaction/@ref").text).to eq(transaction.reference)
    end
  end
end
