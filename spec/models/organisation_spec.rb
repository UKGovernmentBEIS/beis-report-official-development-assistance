require "rails_helper"

RSpec.describe Organisation, type: :model do
  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:organisation_type) }
    it { should validate_presence_of(:language_code) }
    it { should validate_presence_of(:default_currency) }

    it { should validate_uniqueness_of(:name).ignoring_case_sensitivity }
    it { should validate_uniqueness_of(:beis_organisation_reference).ignoring_case_sensitivity }

    context "when the organisation is a service owner" do
      subject { build(:beis_organisation) }
      it { should validate_presence_of(:beis_organisation_reference) }
      it { should validate_presence_of(:iati_reference) }
      it { should validate_uniqueness_of(:iati_reference).ignoring_case_sensitivity }
    end

    context "when the organisation is a partner organisation" do
      subject { build(:partner_organisation) }
      it { should validate_presence_of(:beis_organisation_reference) }
      it { should validate_presence_of(:iati_reference) }
      it { should validate_uniqueness_of(:iati_reference).ignoring_case_sensitivity }
    end

    context "when the organisation is a matched effort provider" do
      subject { build(:matched_effort_provider) }
      it { should_not validate_presence_of(:beis_organisation_reference) }
      it { should_not validate_presence_of(:iati_reference) }
      it { should_not validate_uniqueness_of(:iati_reference).ignoring_case_sensitivity }
    end

    context "when the organisation is a external income provider" do
      subject { build(:external_income_provider) }
      it { should_not validate_presence_of(:beis_organisation_reference) }
      it { should_not validate_presence_of(:iati_reference) }
      it { should_not validate_uniqueness_of(:iati_reference).ignoring_case_sensitivity }
    end

    describe "sanitation" do
      it { should strip_attribute(:iati_reference) }
    end

    describe "#iati_reference" do
      it "returns true if it does matches a known structure XX-XXX-" do
        organisation = build(:partner_organisation, iati_reference: "GB-GOV-13")
        result = organisation.valid?
        expect(result).to eq(true)
      end

      it "returns true if it does match an unexpected value of the same XX-XXX- structure" do
        organisation = build(:partner_organisation, iati_reference: "GB-COH-1234567asdfghj")
        result = organisation.valid?
        expect(result).to eq(true)
      end

      it "returns true if the country code is 3 characters long" do
        organisation = build(:partner_organisation, iati_reference: "CZH-COH-111")
        result = organisation.valid?
        expect(result).to eq(true)
      end

      it "returns false if it doesn't match the structure XX-XXX-" do
        organisation = build(:partner_organisation, iati_reference: "1234")
        result = organisation.valid?
        expect(result).to eq(false)
      end

      it "returns an error message if it is invalid" do
        organisation = build(:partner_organisation, iati_reference: "1234")
        organisation.valid?
        expect(organisation.errors.messages[:iati_reference]).to include(
          t("activerecord.errors.models.organisation.attributes.iati_reference.format")
        )
      end
    end
  end

  describe "::find_matching" do
    let!(:canonical) do
      create(
        :implementing_organisation,
        name: "canonical",
        alternate_names: ["uncanonical", "non_canonical"]
      )
    end

    it "finds the canonical record when the search term matches the name" do
      expect(Organisation.find_matching("canonical"))
        .to eq(canonical)
    end

    it "finds the canonical record when the search term matches any legacy name" do
      aggregate_failures do
        expect(Organisation.find_matching("uncanonical"))
          .to eq(canonical)

        expect(Organisation.find_matching("non_canonical"))
          .to eq(canonical)
      end
    end
  end

  describe "#beis_organisation_reference" do
    it "makes the organisation valid if it is between 2 and 5 characters long" do
      organisation = build(:partner_organisation, beis_organisation_reference: "ABCD")
      result = organisation.valid?
      expect(result).to eq(true)
    end

    it "makes the organisation invalid if it is over 5 characters long" do
      organisation = build(:partner_organisation, beis_organisation_reference: "ABCDEF")
      result = organisation.valid?
      expect(result).to eq(false)
    end

    it "makes the organisation invalid if contains non alphabetical characters" do
      organisation = build(:partner_organisation, beis_organisation_reference: "123")
      result = organisation.valid?
      expect(result).to eq(false)
    end

    it "returns an error message if it is invalid" do
      organisation = build(:partner_organisation, beis_organisation_reference: "ABCDEF")
      organisation.valid?
      expect(organisation.errors.messages[:beis_organisation_reference]).to include(
        t("activerecord.errors.models.organisation.attributes.beis_organisation_reference.format")
      )
    end

    it "does not validate if the organisation is not a reporter" do
      organisation = build(:external_income_provider, beis_organisation_reference: "ABCDEF")
      result = organisation.valid?
      expect(result).to eq(true)
    end
  end

  describe "associations" do
    it { should have_many(:users) }

    let(:organisation) { create(:implementing_organisation) }

    let(:implemented_activity) { create(:programme_activity) }
    let(:other_activity) { create(:programme_activity) }

    let!(:implementing_participation) do
      OrgParticipation.create!(
        activity: implemented_activity,
        organisation: organisation,
        role: "implementing"
      )
    end

    let!(:other_participation) do
      OrgParticipation.create!(
        activity: other_activity,
        organisation: organisation,
        role: "partner_organisation"
      )
    end

    it "associates with #implementing_org_participations with the 'Implementing' role only" do
      expect(organisation.implementing_org_participations).to include(implementing_participation)
      expect(organisation.implementing_org_participations).not_to include(other_participation)
    end

    it "associates with #implemented_activities through the 'Implementing' role only" do
      expect(organisation.implemented_activities).to include(implemented_activity)
      expect(organisation.implemented_activities).not_to include(other_activity)
    end
  end

  describe "service_owner?" do
    context "when an organisation is has been flagged as BEIS" do
      it "should return true" do
        beis_organisation = create(:beis_organisation)

        result = beis_organisation.service_owner?

        expect(result).to eq(true)
      end
    end

    context "when an organisation is a partner organisation" do
      it " should return false" do
        other_organisation = create(:partner_organisation)

        result = other_organisation.service_owner?

        expect(result).to eq(false)
      end
    end

    context "when an organisation is a matched effort provider" do
      it "should return false" do
        other_organisation = create(:matched_effort_provider)

        result = other_organisation.service_owner?

        expect(result).to eq(false)
      end
    end
  end

  describe ".service_owner" do
    let!(:service_owner) { create(:beis_organisation) }
    it "returns the service owner" do
      expect(Organisation.service_owner).to eq(service_owner)
    end
  end

  describe ".sorted_by_name" do
    it "should sort name name a->z" do
      a_organisation = create(:partner_organisation, name: "A", created_at: 3.days.ago)
      b_organisation = create(:partner_organisation, name: "B", created_at: 1.days.ago)
      c_organisation = create(:partner_organisation, name: "C", created_at: 2.days.ago)

      result = Organisation.sorted_by_name

      expect(result.first).to eq(a_organisation)
      expect(result.second).to eq(b_organisation)
      expect(result.third).to eq(c_organisation)
    end
  end

  describe ".partner_organisations" do
    it "should only contain organisations that are partner organisations" do
      beis_organisation = create(:beis_organisation)
      partner_organisation = create(:partner_organisation)
      matched_effort_provider = create(:matched_effort_provider)
      external_income_provider = create(:external_income_provider)
      partner_organisations = Organisation.partner_organisations

      expect(partner_organisations).to include(partner_organisation)
      expect(partner_organisations).not_to include(beis_organisation)
      expect(partner_organisations).not_to include(matched_effort_provider)
      expect(partner_organisations).not_to include(external_income_provider)
    end
  end

  describe ".reporters" do
    it "should only contain partner organisations and service owners" do
      beis_organisation = create(:beis_organisation)
      partner_organisation = create(:partner_organisation)
      matched_effort_provider = create(:matched_effort_provider)
      external_income_provider = create(:external_income_provider)
      implementing_organisation = create(:implementing_organisation)
      reporters = Organisation.reporters

      expect(reporters).to include(partner_organisation)
      expect(reporters).to include(beis_organisation)
      expect(reporters).not_to include(matched_effort_provider)
      expect(reporters).not_to include(external_income_provider)
      expect(reporters).not_to include(implementing_organisation)
    end
  end

  describe ".matched_effort_providers" do
    it "should contain only organisations that are matched effort providers" do
      create_list(:partner_organisation, 3)
      matched_effort_providers = create_list(:matched_effort_provider, 2)

      expect(Organisation.matched_effort_providers).to match_array(matched_effort_providers)
    end
  end

  describe ".external_income_providers" do
    it "should contain only organisations that are external income providers" do
      create_list(:partner_organisation, 3)
      matched_effort_providers = create_list(:matched_effort_provider, 2)

      expect(Organisation.matched_effort_providers).to match_array(matched_effort_providers)
    end
  end

  describe ".implementing" do
    let!(:partner_organisation) { create(:partner_organisation) }
    let!(:matched_effort_provider) { create(:matched_effort_provider) }

    let!(:newly_created_implementing_org) do
      create(:implementing_organisation, role: "implementing_organisation")
    end

    let!(:migrated_implementing_org) do
      create(:implementing_organisation, role: nil).tap do |org|
        OrgParticipation.create!(
          organisation: org,
          activity: create(:project_activity),
          role: "implementing"
        )
      end
    end

    let!(:other_org) do
      create(:partner_organisation, role: "partner_organisation").tap do |org|
        OrgParticipation.create!(
          organisation: org,
          activity: create(:project_activity),
          role: "implementing"
        )
      end
    end

    it "includes migrated organisations with no role and an 'implementing' participation" do
      expect(Organisation.implementing).to include(migrated_implementing_org)
    end

    it "includes new organisations with an 'implementing_organisation' role and no participation" do
      expect(Organisation.implementing).to include(newly_created_implementing_org)
    end

    it "includes legacy organisations with another role and an 'implementing' participation" do
      expect(Organisation.implementing).to include(other_org)
    end

    it "excludes orgs with non-'implementing_organisation' roles and no participation" do
      aggregate_failures do
        expect(Organisation.implementing).not_to include(partner_organisation)
        expect(Organisation.implementing).not_to include(matched_effort_provider)
      end
    end
  end

  describe ".active" do
    it "should contain only active organisations" do
      create_list(:partner_organisation, 3, active: false)
      matched_effort_providers = create_list(:matched_effort_provider, 2, active: true)
      partner_organisations = create_list(:partner_organisation, 3, active: true)

      expect(Organisation.active).to match_array(matched_effort_providers + partner_organisations)
    end
  end

  describe "#is_government?" do
    it "should be true for a Government organisation_type" do
      organisation = create(:partner_organisation, organisation_type: 10)
      expect(organisation.is_government?).to eq true
    end

    it "should be true for a Government organisation_type" do
      organisation = create(:partner_organisation, organisation_type: 11)
      expect(organisation.is_government?).to eq true
    end

    it "should be false for an NGO organisation_type" do
      organisation = create(:partner_organisation, organisation_type: 21)
      expect(organisation.is_government?).to eq false
    end
  end

  describe "#is_reporter?" do
    it "should be true for partner organisations" do
      organisation = build(:partner_organisation)
      expect(organisation.is_reporter?).to eq true
    end

    it "should be true for BEIS" do
      organisation = build(:beis_organisation)
      expect(organisation.is_reporter?).to eq true
    end

    it "should be false for matched effort providers" do
      organisation = build(:matched_effort_provider)
      expect(organisation.is_reporter?).to eq false
    end

    it "should be false for external income providers" do
      organisation = build(:external_income_provider)
      expect(organisation.is_reporter?).to eq false
    end
  end

  describe "#ensure_beis_organisation_reference_is_uppercase" do
    it "converts the value of beis_organisation_reference to uppercase" do
      organisation = build(:partner_organisation, beis_organisation_reference: "test")

      expect(organisation.valid?).to be_truthy
      expect(organisation.beis_organisation_reference).to eql "TEST"
    end
  end
end
