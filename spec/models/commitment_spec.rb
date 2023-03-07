RSpec.describe Commitment do
  it "should be valid" do
    should belong_to(:activity)

    should validate_presence_of(:value)
    should validate_numericality_of(:value).is_greater_than(0)
    should validate_numericality_of(:value).is_less_than_or_equal_to(99_999_999_999.00)

    should validate_presence_of(:transaction_date)
  end
end
