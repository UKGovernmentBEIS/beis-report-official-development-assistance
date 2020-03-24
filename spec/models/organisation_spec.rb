require "rails_helper"

RSpec.describe Organisation, type: :model do
  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:organisation_type) }
    it { should validate_presence_of(:language_code) }
    it { should validate_presence_of(:default_currency) }
    it { should validate_presence_of(:iati_reference) }

    it { should validate_uniqueness_of(:iati_reference).ignoring_case_sensitivity }
  end

  describe "associations" do
    it { should have_many(:users) }
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

  describe ".delivery_partners" do
    it "should contain only organisations that are not BEIS" do
      beis_organisation = create(:beis_organisation)
      delivery_partner_organisation = create(:delivery_partner_organisation)
      delivery_partners = Organisation.delivery_partners

      expect(delivery_partners).to include(delivery_partner_organisation)
      expect(delivery_partners).not_to include(beis_organisation)
    end
  end

  describe "#is_government_organisation?" do
    it "should be true for a Government organisation_type" do
      organisation = create(:organisation, organisation_type: 10)
      expect(organisation.is_government_organisation?).to eq true
    end

    it "should be true for a Government organisation_type" do
      organisation = create(:organisation, organisation_type: 11)
      expect(organisation.is_government_organisation?).to eq true
    end

    it "should be false for an NGO organisation_type" do
      organisation = create(:organisation, organisation_type: 21)
      expect(organisation.is_government_organisation?).to eq false
    end
  end
end
