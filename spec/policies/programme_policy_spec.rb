require "rails_helper"

RSpec.describe ProgrammePolicy do
  let(:organisation) { create(:partner_organisation) }
  let(:programme) { create(:programme_activity, extending_organisation: organisation) }
  let(:another_programme) { create(:programme_activity) }

  subject { described_class.new(user, Activity.all) }

  context "as a user that belongs to BEIS" do
    let(:user) { build_stubbed(:beis_user) }

    it "permits all actions" do
      is_expected.to permit_action(:index)
      is_expected.to permit_action(:show)
      is_expected.to permit_new_and_create_actions
      is_expected.to permit_edit_and_update_actions
      is_expected.to permit_action(:destroy)
    end

    it "includes all programmes in resolved scope" do
      resolved_scope = described_class::Scope.new(user, Activity.programme).resolve
      expect(resolved_scope).to contain_exactly(programme, another_programme)
    end
  end

  context "as a user that does NOT belong to BEIS" do
    let(:user) { create(:partner_organisation_user, organisation: organisation) }

    it "only permits index and show" do
      is_expected.to permit_action(:index)
      is_expected.to permit_action(:show)
      is_expected.to forbid_new_and_create_actions
      is_expected.to forbid_edit_and_update_actions
      is_expected.to forbid_action(:destroy)
    end

    it "includes only programmes that the users organisation is the extending organisation for in resolved scope" do
      resolved_scope = described_class::Scope.new(user, Activity.programme).resolve
      expect(resolved_scope).to include programme
      expect(resolved_scope).not_to include another_programme
    end
  end
end
