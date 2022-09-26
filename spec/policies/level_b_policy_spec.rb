require "rails_helper"

RSpec.describe LevelBPolicy do
  subject { described_class.new(user, nil) }

  context "as user that belongs to BEIS" do
    let(:user) { build_stubbed(:beis_user) }

    it "permits all actions" do
      is_expected.to permit_action(:activity_upload)
      is_expected.to permit_action(:budget_upload)
    end
  end

  context "as user that does NOT belong to BEIS" do
    let(:user) { build_stubbed(:partner_organisation_user) }

    it "forbids all actions" do
      is_expected.to forbid_action(:activity_upload)
      is_expected.to forbid_action(:budget_upload)
    end
  end
end
