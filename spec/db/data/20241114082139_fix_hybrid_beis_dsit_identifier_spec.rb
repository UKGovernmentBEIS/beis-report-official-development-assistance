require Rails.root + "db/data/20241114082139_fix_hybrid_beis_dsit_identifier.rb"

RSpec.describe FixHybridBeisDsitIdentifier do
  describe "#migrate!" do
    it "updates only the appropriate activities and includes a count" do
      activity_to_update = create(
        :programme_activity,
        transparency_identifier: "GB-GOV-26-AAAA-BBBB-CCC-DDDDDDD",
        previous_identifier: "GB-GOV-13-AAAA-BBBB-CCC-DDDDDDD",
        hybrid_beis_dsit_activity: false
      )
      activity_to_ignore = create(
        :programme_activity,
        transparency_identifier: "GB-GOV-26-EEEE-FFFF-GGG-HHHHHHH",
        previous_identifier: nil,
        hybrid_beis_dsit_activity: false
      )
      other_activity_to_ignore = create(
        :programme_activity,
        transparency_identifier: "GB-GOV-13-EEEE-FFFF-GGG-HHHHHHH",
        previous_identifier: "GB-GOV-13-IIII_JJJJ_KKK_LL",
        hybrid_beis_dsit_activity: false
      )

      migration = described_class.new
      migration.migrate!

      expect(activity_to_update.reload.transparency_identifier).to eql "GB-GOV-13-AAAA-BBBB-CCC-DDDDDDD"
      expect(activity_to_update.hybrid_beis_dsit_activity).to be true

      expect(activity_to_ignore.reload.transparency_identifier).to eql "GB-GOV-26-EEEE-FFFF-GGG-HHHHHHH"
      expect(activity_to_ignore.hybrid_beis_dsit_activity).to be false

      expect(other_activity_to_ignore.reload.transparency_identifier).to eql "GB-GOV-13-EEEE-FFFF-GGG-HHHHHHH"
      expect(other_activity_to_ignore.hybrid_beis_dsit_activity).to be false

      expect(migration.target).to be 1
      expect(migration.updated).to be 1
    end
  end

  describe "#identifier_starts_with_beis" do
    it "returns true for identifiers that start GB-GOV-13" do
      valid_identifier = "GB-GOV-13-1234-5678-91011"

      expect(described_class.new.identifier_starts_with_beis(valid_identifier)).to be true
    end

    it "returns false for identifiers that do not start GB-GOV-13" do
      valid_identifier = "GB-GOV-10-1234-5678-91011"

      expect(described_class.new.identifier_starts_with_beis(valid_identifier)).to be false
    end
  end

  describe "#identifier_starts_with_dsit" do
    it "returns true for identifiers that start GB-GOV-26" do
      valid_identifier = "GB-GOV-26-1234-5678-91011"

      expect(described_class.new.identifier_starts_with_dsit(valid_identifier)).to be true
    end

    it "returns false for identifiers that do not start GB-GOV-26" do
      valid_identifier = "GB-GOV-10-1234-5678-91011"

      expect(described_class.new.identifier_starts_with_dsit(valid_identifier)).to be false
    end
  end

  describe "#fix_activity" do
    let(:activity) do
      create(
        :programme_activity,
        transparency_identifier: "GB-GOV-26-AAAA-BBBB-CCC-DDDDDDD",
        previous_identifier: "GB-GOV-13-AAAA-BBBB-CCC-DDDDDDD",
        hybrid_beis_dsit_activity: false
      )
    end

    it "updates the transparency_identifier to the value of previous_identifier" do
      described_class.new.fix_activity(activity)

      expect(activity.transparency_identifier).to eql "GB-GOV-13-AAAA-BBBB-CCC-DDDDDDD"
    end

    it "updates the previous_identifier to nil" do
      described_class.new.fix_activity(activity)

      expect(activity.previous_identifier).to be_nil
    end

    it "updates the hybrid BEIS DSIT state to true" do
      described_class.new.fix_activity(activity)

      expect(activity.hybrid_beis_dsit_activity).to be true
    end
  end
end
