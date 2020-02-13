require "rails_helper"

RSpec.describe ImplementingOrganisation, type: :model do
  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:organisation_type) }
  end

  describe "associations" do
    it { should belong_to(:activity) }
  end
end
