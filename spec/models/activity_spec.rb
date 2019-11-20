require "rails_helper"

RSpec.describe Activity, type: :model do
  describe "relations" do
    it { should belong_to(:fund) }
  end

  describe "constraints" do
    it { should validate_uniqueness_of(:identifier) }
  end
end
