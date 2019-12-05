require "rails_helper"

RSpec.describe Transaction, type: :model do
  describe "relations" do
    it { should belong_to(:fund) }
  end

  describe "validations" do
    it { should validate_presence_of(:reference) }
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:transaction_type) }
    it { should validate_presence_of(:date) }
    it { should validate_presence_of(:currency) }
    it { should validate_presence_of(:value) }
    it { should validate_presence_of(:disbursement_channel) }
  end
end
