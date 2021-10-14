RSpec.describe Commitment do
  it "should be valid" do
    should belong_to(:activity)

    should validate_presence_of(:value)
    should validate_numericality_of(:value).is_greater_than(0)
    should validate_numericality_of(:value).is_less_than_or_equal_to(99_999_999_999.00)

    should validate_presence_of(:financial_quarter)
    should validate_inclusion_of(:financial_quarter).in_array((1..4).to_a)

    should validate_presence_of(:financial_year)
    should validate_numericality_of(:financial_year).only_integer
    should validate_numericality_of(:financial_year).is_greater_than_or_equal_to(2_000)
    should validate_numericality_of(:financial_year).is_less_than_or_equal_to(3_000)
  end
end
