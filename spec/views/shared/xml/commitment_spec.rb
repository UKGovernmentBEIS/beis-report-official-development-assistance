RSpec.describe "shared/xml/commitment" do
  before do
    render partial: "shared/xml/commitment", locals: {commitment: commitment}
  end

  context "when there is a commitment" do
    let(:commitment) { build(:commitment) }
    subject { Nokogiri::XML::Document.parse(rendered) }

    it "has the correct transaction type (2 = commitment)" do
      expect(subject.at("transaction/transaction-type/@code").text).to eq "2"
    end

    it "has the transation date" do
      expect(subject.at("transaction/transaction-date/@iso-date").text)
        .to eq l(commitment.first_day_of_financial_period, format: :iati)
    end

    it "has the value and attributes" do
      expect(subject.at("transaction/value").text)
        .to eq commitment.value.to_s
      expect(subject.at("transaction/value/@value-date").text)
        .to eq l(commitment.first_day_of_financial_period, format: :iati)
    end
  end
end
