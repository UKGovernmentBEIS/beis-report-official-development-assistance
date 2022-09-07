require "rails_helper"

RSpec.describe UserPolicy do
  subject { described_class.new(user, target_user) }

  let(:target_user) { create(:administrator) }

  context "as user that belongs to BEIS" do
    let(:user) { build_stubbed(:beis_user) }

    it "permits all actions" do
      is_expected.to permit_action(:index)
      is_expected.to permit_action(:show)
      is_expected.to permit_new_and_create_actions
      is_expected.to permit_edit_and_update_actions
      is_expected.to permit_action(:destroy)
    end
  end

  context "as user that does NOT belong to BEIS" do
    let(:user) { build_stubbed(:partner_organisation_user) }

    it "forbids all actions" do
      is_expected.to forbid_action(:index)
      is_expected.to forbid_action(:show)
      is_expected.to forbid_new_and_create_actions
      is_expected.to forbid_edit_and_update_actions
      is_expected.to forbid_action(:destroy)
    end
  end
end
