require "rails_helper"

RSpec.describe ProjectPolicy do
  let(:organisation) { create(:delivery_partner_organisation) }
  let(:project) { create(:project_activity, organisation: organisation) }
  let(:another_project) { create(:project_activity) }

  subject { described_class.new(user, Activity.project) }

  context "as a user that belongs to BEIS" do
    let(:user) { build_stubbed(:beis_user) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to forbid_new_and_create_actions }
    it { is_expected.to forbid_edit_and_update_actions }
    it { is_expected.to forbid_action(:destroy) }
    it { is_expected.to permit_action(:download) }
    it { is_expected.to permit_action(:redact_from_iati) }

    it "includes all projects in the resolved scope" do
      resolved_scope = described_class::Scope.new(user, Activity.project).resolve
      expect(resolved_scope).to contain_exactly(project, another_project)
    end
  end

  context "as a user that does NOT belong to BEIS" do
    let(:user) { build_stubbed(:delivery_partner_user, organisation: organisation) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_new_and_create_actions }
    it { is_expected.to permit_edit_and_update_actions }
    it { is_expected.to forbid_action(:destroy) }
    it { is_expected.to forbid_action(:download) }
    it { is_expected.to forbid_action(:redact_from_iati) }

    it "includes only projects that the users organisation is reporting the project in the resolved scope" do
      resolved_scope = described_class::Scope.new(user, Activity.project).resolve
      expect(resolved_scope).to include project
      expect(resolved_scope).not_to include another_project
    end
  end
end
