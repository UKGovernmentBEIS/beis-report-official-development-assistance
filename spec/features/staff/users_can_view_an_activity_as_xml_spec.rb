RSpec.feature "Users can download an activity as XML" do
  before do
    authenticate!(user: user)
  end

  let(:organisation) { create(:beis_organisation) }
  let(:delivery_partner) { create(:organisation) }
  let(:activity) do
    create(:activity,
      planned_start_date: Date.today,
      planned_end_date: Date.tomorrow,
      organisation: organisation,
      extending_organisation: delivery_partner)
  end
  let(:user) { create(:administrator, organisation: organisation) }

  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      page.set_rack_session(userinfo: nil)
      visit organisation_activity_path(activity.organisation, activity)
      expect(current_path).to eq(root_path)
    end
  end

  context "when the user belongs to the organisation the activity is part of" do
    it "returns an XML response" do
      visit organisation_activity_path(activity.organisation, activity, format: :xml)

      xml = Nokogiri::XML::Document.parse(page.body)

      expect(xml.at("iati-identifier").text).to eq(activity.identifier)
      expect(xml.at("reporting-org/@ref").text).to eq(activity.organisation.iati_reference)
      expect(xml.at("reporting-org/@type").text).to eq(activity.organisation.organisation_type)
      expect(xml.at("reporting-org/narrative").text).to eq(organisation.name)
      expect(xml.at("title/narrative").text).to eq(activity.title)
      expect(xml.at("description/narrative").text).to eq(activity.description)
      expect(xml.at("activity-status/@code").text).to eq(activity.status)
      expect(xml.at("activity-date[@type = '1']/@iso-date").text).to eq(activity.planned_start_date.strftime("%Y-%m-%d"))
      expect(xml.at("activity-date[@type = '2']/@iso-date").text).to eq(activity.actual_start_date.strftime("%Y-%m-%d"))
      expect(xml.at("activity-date[@type = '3']/@iso-date").text).to eq(activity.planned_end_date.strftime("%Y-%m-%d"))
      expect(xml.at("activity-date[@type = '4']/@iso-date").text).to eq(activity.actual_end_date.strftime("%Y-%m-%d"))
      expect(xml.at("recipient-region/@code").text).to eq(activity.recipient_region)
      expect(xml.at("sector[@vocabulary = '1']/@code").text).to eq(activity.sector)
      expect(xml.at("default-flow-type/@code").text).to eq(activity.flow)
      expect(xml.at("default-finance-type/@code").text).to eq(activity.finance)
      expect(xml.at("default-tied-status/@code").text).to eq(activity.tied_status)
    end
  end

  context "when an activity has a transaction" do
    it "returns an XML response with the transaction included" do
      transaction = create(:transaction, activity: activity)
      visit organisation_activity_path(activity.organisation, activity, format: :xml)

      xml = Nokogiri::XML::Document.parse(page.body)

      expect(xml.at("transaction/@ref").text).to eq(transaction.reference)
      expect(xml.at("transaction-type/@code").text).to eq(transaction.transaction_type)
      expect(xml.at("transaction-date/@iso-date").text).to eq(transaction.date.strftime("%Y-%m-%d"))
      expect(xml.at("value/@currency").text).to eq(transaction.currency)
      expect(xml.at("value/@value-date").text).to eq(transaction.date.strftime("%Y-%m-%d"))
      expect(xml.at("value").text).to eq(transaction.value.to_s)
      expect(xml.at("transaction/description/narrative").text).to eq(transaction.description)
      expect(xml.at("provider-org/@type").text).to eq(transaction.providing_organisation_type)
      expect(xml.at("provider-org/@ref").text).to eq(transaction.providing_organisation_reference)
      expect(xml.at("provider-org/narrative").text).to eq(transaction.providing_organisation_name)
      expect(xml.at("receiver-org/@type").text).to eq(transaction.receiving_organisation_type)
      expect(xml.at("receiver-org/@ref").text).to eq(transaction.receiving_organisation_reference)
      expect(xml.at("receiver-org/narrative").text).to eq(transaction.receiving_organisation_name)
      expect(xml.at("disbursement-channel/@code").text).to eq(transaction.disbursement_channel)
    end
  end
end
