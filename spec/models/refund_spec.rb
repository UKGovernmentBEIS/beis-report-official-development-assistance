require "rails_helper"

RSpec.describe Refund, type: :model do
  let(:refund) { build(:refund) }

  it { should belong_to(:parent_activity) }
  it { should belong_to(:report) }

  it { should validate_presence_of(:financial_quarter) }
  it { should validate_presence_of(:financial_year) }
  it { should validate_presence_of(:value) }
end
