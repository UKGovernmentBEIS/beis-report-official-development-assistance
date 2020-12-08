require "rails_helper"

RSpec.describe ImplementingOrganisation, type: :model do
  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:organisation_type) }

    describe ".organisation_type" do
      it { is_expected.to allow_value("80").for(:organisation_type) }
      it { is_expected.not_to allow_value("").for(:organisation_type) }
      it { is_expected.not_to allow_value("invalid").for(:organisation_type) }
    end
  end

  describe "sanitation" do
    it { should strip_attribute(:name) }
    it { should strip_attribute(:reference) }
  end

  describe "associations" do
    it { should belong_to(:activity) }
  end
end
