require "rails_helper"

RSpec.describe Activity::RodaIdentifierGenerator do
  describe "#generate" do
    let(:extending_organisation) { build(:partner_organisation) }

    subject do
      described_class.new(
        parent_activity: parent_activity,
        extending_organisation: extending_organisation
      ).generate
    end

    before do
      expect(Nanoid).to receive(:generate).with(
        size: 7, alphabet: "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"
      ).and_return("3455ABC")
    end

    context "when the parent activity is a fund" do
      let(:parent_activity) { build(:fund_activity) }

      it "generates a RODA identifier" do
        expect(subject).to eq("#{parent_activity.roda_identifier}-#{extending_organisation.beis_organisation_reference}-3455ABC")
      end
    end

    context "when the parent activity is a programme" do
      let(:parent_activity) { build(:programme_activity) }

      it "generates a RODA identifier" do
        expect(subject).to eq("#{parent_activity.roda_identifier}-3455ABC")
      end
    end

    context "when the parent activity is a project" do
      let(:parent_activity) { build(:project_activity) }

      it "generates a RODA identifier" do
        expect(subject).to eq("#{parent_activity.roda_identifier}-3455ABC")
      end
    end
  end
end
