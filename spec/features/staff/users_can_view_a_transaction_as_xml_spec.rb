RSpec.feature "Users can view a transaction as XML" do
  before do
    authenticate!(user: user)
  end

  let(:organisation) { create(:organisation) }
  let(:fund) { create(:fund, organisation: organisation) }
  let!(:activity) { create(:activity, hierarchy: fund) }
  let(:transaction) { create(:transaction, fund: fund) }
  let(:user) { create(:administrator, organisation: organisation) }

  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      page.set_rack_session(userinfo: nil)
      visit fund_transaction_path(id: transaction, fund_id: fund)
      expect(current_path).to eq(root_path)
    end
  end

  context "when the user belongs to the organisation the activity is part of" do
    it "returns an XML response" do
      visit fund_transaction_path(id: transaction, fund_id: fund, format: :xml)

      xml = Nokogiri::XML::Document.parse(page.body)
      expect(xml.at("transaction/@ref").text).to eq(transaction.reference)
      expect(xml.at("transaction-type/@code").text).to eq(transaction.transaction_type)
      expect(xml.at("transaction-date/@iso-date").text).to eq(transaction.date.strftime("%Y-%m-%d"))
      expect(xml.at("value/@currency").text).to eq(transaction.currency)
      expect(xml.at("value/@value-date").text).to eq(transaction.date.strftime("%Y-%m-%d"))
      expect(xml.at("value").text).to eq(transaction.value.to_s)
      expect(xml.at("description/narrative").text).to eq(transaction.description)
      expect(xml.at("provider-org/@type").text).to eq(transaction.provider.organisation_type)
      expect(xml.at("provider-org/narrative").text).to eq(transaction.provider.name)
      expect(xml.at("receiver-org/@type").text).to eq(transaction.receiver.organisation_type)
      expect(xml.at("receiver-org/narrative").text).to eq(transaction.receiver.name)
      expect(xml.at("disbursement-channel/@code").text).to eq(transaction.disbursement_channel)
    end
  end
end
