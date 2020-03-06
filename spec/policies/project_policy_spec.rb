require "rails_helper"

RSpec.describe ProjectPolicy do
  subject { described_class.new(user, activity) }

  let(:organisation) { create(:organisation) }
  let(:activity) { create(:project_activity, organisation: organisation) }

  context "as a user that belongs to BEIS" do
    let(:user) { build_stubbed(:beis_user) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to forbid_new_and_create_actions }
    it { is_expected.to forbid_edit_and_update_actions }
    it { is_expected.to forbid_action(:destroy) }
    it { is_expected.to permit_action(:download) }

    it "includes activity in resolved scope" do
      resolved_scope = described_class::Scope.new(user, Activity.all).resolve
      expect(resolved_scope).to include(activity)
    end
  end

  context "as a user that does NOT belong to BEIS" do
    let(:user) { build_stubbed(:delivery_partner_user) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_new_and_create_actions }
    it { is_expected.to permit_edit_and_update_actions }
    it { is_expected.to forbid_action(:destroy) }
    it { is_expected.to forbid_action(:download) }

    it "includes activity in resolved scope" do
      resolved_scope = described_class::Scope.new(user, Activity.all).resolve
      expect(resolved_scope).to eq(Activity.all)
    end
  end
end
