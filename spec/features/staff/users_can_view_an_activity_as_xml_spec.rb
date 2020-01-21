RSpec.feature "Users can download an activity as XML" do
  before do
    authenticate!(user: user)
  end

  let(:organisation) { create(:organisation) }
  let(:fund) { create(:fund, organisation: organisation) }
  let(:activity) do
    create(:activity,
      hierarchy: fund,
      planned_start_date: Date.today,
      planned_end_date: Date.tomorrow)
  end
  let(:user) { create(:administrator, organisation: organisation) }

  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      page.set_rack_session(userinfo: nil)
      visit fund_activity_path(id: activity, fund_id: fund)
      expect(current_path).to eq(root_path)
    end
  end

  context "when the user belongs to the organisation the activity is part of" do
    it "returns an XML response" do
      visit fund_activity_path(id: activity, fund_id: fund, format: :xml)

      xml = Nokogiri::XML::Document.parse(page.body)

      expect(xml.at("iati-identifier").text).to eq(activity.identifier)
      expect(xml.at("reporting-org/narrative").text).to eq(organisation.name)
      expect(xml.at("title/narrative").text).to eq(activity.title)
      expect(xml.at("description/narrative").text).to eq(activity.description)
      expect(xml.at("activity-status/@code").text).to eq(activity.status)
      expect(xml.at("activity-date[@type = '1']/@iso-date").text).to eq(activity.planned_start_date.strftime("%Y-%m-%d"))
      expect(xml.at("activity-date[@type = '2']/@iso-date").text).to eq(activity.planned_end_date.strftime("%Y-%m-%d"))
      expect(xml.at("recipient-region/@code").text).to eq(activity.recipient_region)
      expect(xml.at("sector[@vocabulary = '1']/@code").text).to eq(activity.sector)
      expect(xml.at("default-flow-type/@code").text).to eq(activity.flow)
      expect(xml.at("default-finance-type/@code").text).to eq(activity.finance)
      expect(xml.at("default-tied-status/@code").text).to eq(activity.tied_status)
    end
  end
end
