RSpec.describe "Rollout" do
  it "has two custom groups for BEIS users and PO users" do
    expect(ROLLOUT.groups).to include(:beis_users, :partner_organisation_users)
  end

  context "a BEIS user" do
    let(:user) { build(:beis_user) }

    it "is part of the beis_users group and not the partner_organisation_users group" do
      expect(ROLLOUT.active_in_group?(:beis_users, user)).to be true
      expect(ROLLOUT.active_in_group?(:partner_organisation_users, user)).to be false
    end
  end

  context "a partner organisation user" do
    let(:user) { build(:partner_organisation_user) }

    it "is part of the partner_organisation_users group and not the beis_users group" do
      expect(ROLLOUT.active_in_group?(:beis_users, user)).to be false
      expect(ROLLOUT.active_in_group?(:partner_organisation_users, user)).to be true
    end
  end
end
