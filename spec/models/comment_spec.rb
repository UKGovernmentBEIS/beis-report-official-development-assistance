require "rails_helper"

RSpec.describe Comment, type: :model do
  describe "associations" do
    it { should belong_to(:owner) }
    it { should belong_to(:activity) }
    it { should belong_to(:report) }
  end

  describe "validations" do
    it { should validate_presence_of(:owner) }
    it { should validate_presence_of(:activity) }
    it { should validate_presence_of(:report) }
  end
end
