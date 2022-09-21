require "rails_helper"

RSpec.describe ThirdPartyProjectPolicy do
  let(:organisation) { create(:partner_organisation) }
  let(:third_party_project) { create(:third_party_project_activity, organisation: organisation) }
  let(:another_third_party_project) { create(:third_party_project_activity) }

  subject { described_class.new(user, third_party_project) }

  context "as a user that belongs to BEIS" do
    let(:user) { build_stubbed(:beis_user) }

    it "controls actions as expected" do
      is_expected.to permit_action(:index)
      is_expected.to permit_action(:show)
      is_expected.to forbid_new_and_create_actions
      is_expected.to forbid_edit_and_update_actions
      is_expected.to forbid_action(:destroy)
      is_expected.to permit_action(:download)
      is_expected.to permit_action(:redact_from_iati)
    end

    it "includes all third party projects in the resolved scope" do
      resolved_scope = described_class::Scope.new(user, Activity.third_party_project).resolve
      expect(resolved_scope).to contain_exactly(third_party_project, another_third_party_project)
    end
  end

  context "as a user that does NOT belong to BEIS" do
    let(:user) { build_stubbed(:partner_organisation_user, organisation: organisation) }

    it "controls actions as expected" do
      is_expected.to permit_action(:index)
      is_expected.to permit_action(:show)
      is_expected.to forbid_new_and_create_actions
      is_expected.to permit_edit_and_update_actions
      is_expected.to forbid_action(:destroy)
      is_expected.to forbid_action(:download)
      is_expected.to forbid_action(:redact_from_iati)
    end

    context "with an editable report" do
      let(:third_party_project) { create(:third_party_project_activity, :with_report, organisation: organisation) }

      it { is_expected.to permit_new_and_create_actions }
    end

    it "includes only projects that the users organisation is reporting the project in the resolved scope" do
      resolved_scope = described_class::Scope.new(user, Activity.third_party_project).resolve
      expect(resolved_scope).to include third_party_project
      expect(resolved_scope).not_to include another_third_party_project
    end
  end
end
