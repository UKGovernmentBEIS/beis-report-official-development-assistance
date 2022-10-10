require "rails_helper"

RSpec.describe OrgParticipation, type: :model do
  it { should belong_to(:activity) }
  it { should belong_to(:organisation) }

  context "when the org participation is unpersisted" do
    context "when the role is implementing and the organisation is inactive" do
      subject(:org_participation) { build(:org_participation, :inactive_organisation) }

      it "should not be valid" do
        expect(org_participation).to_not be_valid
      end
    end

    describe "#organisation_is_active" do
      context "when the organisation is active" do
        subject(:org_participation) { build(:org_participation) }

        it "should be valid" do
          expect(org_participation).to be_valid
        end
      end

      context "when the organisation is inactive" do
        subject(:org_participation) { build(:org_participation, :inactive_organisation) }

        it "has an appropriate error" do
          expect(org_participation).to_not be_valid
          expect(org_participation.errors.count).to eq(1)
          expect(org_participation.errors.full_messages.first).to eq(I18n.t("activerecord.errors.models.org_participation.attributes.organisation.inactive"))
        end
      end
    end
  end

  context "when the org participation is persisted" do
    let(:existing_org_participation) { create(:org_participation) }

    context "when the role is implementing and the organisation becomes inactive" do
      it "should be valid" do
        existing_org_participation.organisation.update(active: false)

        expect(existing_org_participation).to be_valid
      end
    end
  end
end
