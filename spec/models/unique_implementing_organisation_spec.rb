require "rails_helper"

RSpec.describe UniqueImplementingOrganisation, type: :model do
  describe "associations" do
    let(:organisation) { create(:unique_implementing_org) }

    let(:implemented_activity) { create(:programme_activity) }
    let(:other_activity) { create(:programme_activity) }

    let!(:implementing_participation) do
      OrgParticipation.create(
        activity: implemented_activity,
        organisation: organisation,
        role: "Implementing"
      )
    end

    let!(:other_participation) do
      OrgParticipation.create(
        activity: other_activity,
        organisation: organisation,
        role: "Other"
      )
    end

    it "associates with org_participations with the 'Implementing' role only" do
      expect(organisation.org_participations).to include(implementing_participation)
      expect(organisation.org_participations).not_to include(other_participation)
    end

    it "associates with activities through the 'Implementing' role only" do
      expect(organisation.activities).to include(implemented_activity)
      expect(organisation.activities).not_to include(other_activity)
    end
  end

  describe "::find_matching" do
    let!(:canonical) do
      create(
        :unique_implementing_org,
        name: "canonical",
        legacy_names: ["uncanonical", "non_canonical"]
      )
    end

    it "finds the canonical record when the search term matches the name" do
      expect(UniqueImplementingOrganisation.find_matching("canonical"))
        .to eq(canonical)
    end

    it "finds the canonical record when the search term matches any legacy name" do
      aggregate_failures do
        expect(UniqueImplementingOrganisation.find_matching("uncanonical"))
          .to eq(canonical)

        expect(UniqueImplementingOrganisation.find_matching("non_canonical"))
          .to eq(canonical)
      end
    end
  end

  describe "::with_legacy_name scope" do
    let!(:canonical) do
      create(
        :unique_implementing_org,
        name: "canonical",
        legacy_names: ["uncanonical", "non_canonical"]
      )
    end

    it "finds the cananonical record when the search matches any legacy name" do
      aggregate_failures do
        expect(UniqueImplementingOrganisation.with_legacy_name("uncanonical"))
          .to include(canonical)

        expect(UniqueImplementingOrganisation.with_legacy_name("non_canonical"))
          .to include(canonical)
      end
    end
  end
end
