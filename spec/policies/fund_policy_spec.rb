require "rails_helper"

RSpec.describe FundPolicy do
  subject { described_class.new(user, activity) }

  let(:activity) { create(:fund_activity) }

  context "as a user that belongs to BEIS" do
    let(:user) { build_stubbed(:beis_user) }

    it "permits all actions" do
      is_expected.to permit_action(:index)
      is_expected.to permit_action(:show)
      is_expected.to permit_new_and_create_actions
      is_expected.to permit_edit_and_update_actions
      is_expected.to permit_action(:destroy)
    end

    it "includes activity in resolved scope" do
      resolved_scope = described_class::Scope.new(user, Activity.all).resolve
      expect(resolved_scope).to include(activity)
    end
  end

  context "as a user that does NOT belong to BEIS" do
    let(:user) { build_stubbed(:partner_organisation_user) }

    it "forbids all actions" do
      is_expected.to forbid_action(:index)
      is_expected.to forbid_action(:show)
      is_expected.to forbid_new_and_create_actions
      is_expected.to forbid_edit_and_update_actions
      is_expected.to forbid_action(:destroy)
    end

    it "includes activity in resolved scope" do
      resolved_scope = described_class::Scope.new(user, Activity.all).resolve
      expect(resolved_scope).to eq(Activity.none)
    end
  end
end
