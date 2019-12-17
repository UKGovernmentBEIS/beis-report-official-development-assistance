require "rails_helper"

RSpec.describe Organisation, type: :model do
  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:organisation_type) }
    it { should validate_presence_of(:language_code) }
    it { should validate_presence_of(:default_currency) }
  end

  describe "associations" do
    it { should have_and_belong_to_many(:users) }
  end

  describe ".sorted_by_name" do
    it "should sort name name a->z" do
      a_organisation = create(:organisation, name: "A", created_at: 3.days.ago)
      b_organisation = create(:organisation, name: "B", created_at: 1.days.ago)
      c_organisation = create(:organisation, name: "C", created_at: 2.days.ago)

      result = Organisation.sorted_by_name

      expect(result.first).to eq(a_organisation)
      expect(result.second).to eq(b_organisation)
      expect(result.third).to eq(c_organisation)
    end
  end
end
