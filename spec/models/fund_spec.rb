require "rails_helper"

RSpec.describe Fund, type: :model do
  describe "validations" do
    it { should validate_presence_of(:name) }
  end

  describe "relations" do
    it { should belong_to(:organisation) }
    it { should have_one(:activity) }
    it { should have_many(:programmes) }
  end
end
