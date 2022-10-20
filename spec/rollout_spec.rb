RSpec.describe "Rollout" do
  it "has two custom groups for BEIS users and PO users", :use_original_rollout do
    expect(ROLLOUT.groups).to include(:beis_users, :partner_organisation_users)
  end

  context "a BEIS user" do
    let(:user) { build(:beis_user) }

    it "is part of the beis_users group and not the partner_organisation_users group", :use_original_rollout do
      expect(ROLLOUT.active_in_group?(:beis_users, user)).to be true
      expect(ROLLOUT.active_in_group?(:partner_organisation_users, user)).to be false
    end
  end

  context "a partner organisation user" do
    let(:user) { build(:partner_organisation_user) }

    it "is part of the partner_organisation_users group and not the beis_users group", :use_original_rollout do
      expect(ROLLOUT.active_in_group?(:beis_users, user)).to be false
      expect(ROLLOUT.active_in_group?(:partner_organisation_users, user)).to be true
    end
  end

  describe "#ispf_in_stealth_mode_for_group?" do
    it "provides a more readable interface to check if the feature is enabled for that group" do
      mock_feature = double(:feature, groups: [:real_group])
      allow(ROLLOUT).to receive(:get).with(:ispf_fund_in_stealth_mode).and_return(mock_feature)

      expect(ispf_in_stealth_mode_for_group?(:real_group)).to be true
      expect(ispf_in_stealth_mode_for_group?(:fake_group)).to be false
    end
  end

  describe "#ispf_in_stealth_mode_for_user?" do
    let(:user) { double(:user) }

    it "provides a more readable interface to check if the feature is enabled for that user" do
      expect(ROLLOUT).to receive(:active?).with(:ispf_fund_in_stealth_mode, user)

      ispf_in_stealth_mode_for_user?(user)
    end
  end
end
