RSpec.shared_examples_for "transaction report history" do
  it "returns the transaction value for a particular quarter" do
    expected_values.each do |quarter, year, amount|
      value = overview.value_for(financial_quarter: quarter, financial_year: year, activity: project)
      expect(value).to eq(amount)
    end
  end

  it "returns the transaction value for a particular quarter using a bulk load" do
    expected_values.each do |quarter, year, amount|
      value = overview.all_quarters.value_for(financial_quarter: quarter, financial_year: year, activity: project)
      expect(value).to eq(amount)
    end
  end
end
