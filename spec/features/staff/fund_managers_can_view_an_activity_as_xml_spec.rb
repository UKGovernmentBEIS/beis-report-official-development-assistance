# TODO: This data will eventually need to be public so that IATI can retrieve it
RSpec.feature "Fund managers can view an activity as XML" do
  context "when the user belongs to the organisation the activity is part of" do
    let(:organisation) { create(:organisation) }

    before { authenticate!(user: create(:fund_manager, organisation: organisation)) }

    context "when the activity is a fund activity" do
      it "returns an XML response" do
        activity = create(:fund_activity, organisation: organisation, identifier: "IND-ENT-IFIER")
        transaction = create(:transaction, activity: activity)

        visit organisation_activity_path(organisation, activity, format: :xml)

        xml = Nokogiri::XML::Document.parse(page.body)

        # The activity XML is present
        expect(xml.at("iati-activity/@default-currency").text).to eq(activity.default_currency)
        expect(xml.at("iati-activity/iati-identifier").text).to eq(activity.identifier)

        # The funding organisation XML is present
        expect(xml.at("iati-activity/participating-org[@role = '1']/@ref").text).to eq(activity.funding_organisation_reference)
        expect(xml.at("iati-activity/participating-org[@role = '1']/@type").text).to eq(activity.funding_organisation_type)
        expect(xml.at("iati-activity/participating-org[@role = '1']/narrative").text).to eq(activity.funding_organisation_name)

        # The accountable organisation XML is present
        expect(xml.at("iati-activity/participating-org[@role = '2']/@ref").text).to eq(activity.accountable_organisation_reference)
        expect(xml.at("iati-activity/participating-org[@role = '2']/@type").text).to eq(activity.accountable_organisation_type)
        expect(xml.at("iati-activity/participating-org[@role = '2']/narrative").text).to eq(activity.accountable_organisation_name)

        # The extending organisation XML is present
        expect(xml.at("iati-activity/participating-org[@role = '3']/@ref").text).to eq(activity.extending_organisation_reference)
        expect(xml.at("iati-activity/participating-org[@role = '3']/@type").text).to eq(activity.extending_organisation_type)
        expect(xml.at("iati-activity/participating-org[@role = '3']/narrative").text).to eq(activity.extending_organisation_name)

        # The transaction XML is present
        expect(xml.at("iati-activity/transaction/@ref").text).to eq(transaction.reference)
      end
    end

    context "when the activity is a programme activity" do
      it "returns an XML response" do
        activity = create(:programme_activity, organisation: organisation, identifier: "IND-ENT-IFIER")

        visit organisation_activity_path(organisation, activity, format: :xml)

        xml = Nokogiri::XML::Document.parse(page.body)

        # The activity XML is present
        expect(xml.at("iati-activity/@default-currency").text).to eq(activity.default_currency)
        expect(xml.at("iati-activity/iati-identifier").text).to eq(activity.identifier)

        # The funding organisation XML is present
        expect(xml.at("iati-activity/participating-org[@role = '1']/@ref").text).to eq(activity.funding_organisation_reference)
        expect(xml.at("iati-activity/participating-org[@role = '1']/@type").text).to eq(activity.funding_organisation_type)
        expect(xml.at("iati-activity/participating-org[@role = '1']/narrative").text).to eq(activity.funding_organisation_name)

        # The accountable organisation XML is present
        expect(xml.at("iati-activity/participating-org[@role = '2']/@ref").text).to eq(activity.accountable_organisation_reference)
        expect(xml.at("iati-activity/participating-org[@role = '2']/@type").text).to eq(activity.accountable_organisation_type)
        expect(xml.at("iati-activity/participating-org[@role = '2']/narrative").text).to eq(activity.accountable_organisation_name)
      end
    end
  end
end
