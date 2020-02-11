require "rails_helper"

RSpec.describe ActivityPolicy do
  subject { described_class.new(user, activity) }

  let(:organisation) { create(:organisation) }
  let(:activity) { create(:activity, organisation: organisation) }

  context "as an administrator" do
    let(:user) { build_stubbed(:administrator) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_new_and_create_actions }
    it { is_expected.to permit_edit_and_update_actions }
    it { is_expected.to permit_action(:destroy) }

    it "includes activity in resolved scope" do
      resolved_scope = described_class::Scope.new(user, Activity.all).resolve
      expect(resolved_scope).to include(activity)
    end
  end

  context "as a fund_manager" do
    let(:user) { build_stubbed(:fund_manager, organisation: organisation) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_new_and_create_actions }
    it { is_expected.to permit_edit_and_update_actions }
    it { is_expected.to permit_action(:destroy) }

    it "includes activity in resolved scope" do
      resolved_scope = described_class::Scope.new(user, Activity.all).resolve
      expect(resolved_scope).to include(activity)
    end
  end

  context "as a delivery_partner" do
    let(:user) { build_stubbed(:delivery_partner) }
    let(:resolved_scope) do
      described_class::Scope.new(user, Activity.all).resolve
    end

    it { is_expected.to permit_action(:index) }
    it { is_expected.to forbid_action(:destroy) }

    context "with activities from my own organisation" do
      let(:user) { create(:delivery_partner, organisation: organisation) }
      let(:project) { create(:project_activity, organisation: organisation) }
      let(:programme) { create(:programme_activity, organisation: organisation) }

      context "with a fund activity" do
        it { is_expected.to permit_action(:show) }
        it { is_expected.to forbid_new_and_create_actions }
        it { is_expected.to forbid_edit_and_update_actions }
      end

      context "with a programme activity" do
        let(:activity) { programme }
        it { is_expected.to permit_action(:show) }
        it { is_expected.to forbid_new_and_create_actions }
        it { is_expected.to forbid_edit_and_update_actions }
      end

      context "with a project activity" do
        let(:activity) { project }
        it { is_expected.to permit_action(:show) }
        it { is_expected.to permit_new_and_create_actions }
        it { is_expected.to permit_edit_and_update_actions }
      end

      it "includes fund activities in resolved scope" do
        expect(resolved_scope).to include(activity)
      end

      it "includes project activities in resolved scope" do
        expect(resolved_scope).to include(project)
      end

      it "includes programme activities in resolved scope" do
        expect(resolved_scope).to include(programme)
      end
    end

    context "with activities from another organisation" do
      let(:other_organisation) { create(:organisation) }
      let(:forbidden_activity) { create(:activity, organisation: other_organisation) }

      it "does not include activity in resolved scope" do
        expect(resolved_scope).to_not include(forbidden_activity)
      end
    end
  end
end
