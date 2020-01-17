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

  describe "service_owner?" do
    context "when an organisation is has been flagged as BEIS" do
      it "should return true" do
        beis_organisation = create(:organisation, service_owner: true)

        result = beis_organisation.service_owner?

        expect(result).to eq(true)
      end
    end
    context "when an organisation is not flagged as BEIS" do
      it " should return false" do
        other_organisation = create(:organisation, service_owner: false)

        result = other_organisation.service_owner?

        expect(result).to eq(false)
      end
    end
    context "when an organisation is not deliberately flagged as BEIS" do
      it "should default to false" do
        new_organisation = create(:organisation)

        result = new_organisation.service_owner?

        expect(result).to eq(false)
      end
    end
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
