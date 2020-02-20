require "rails_helper"

RSpec.describe ActivityPolicy do
  subject { described_class.new(user, activity) }

  context "when the user belongs to BEIS" do
    let(:user) { build_stubbed(:beis_user) }

    context "when the activity is a fund" do
      let(:activity) { create(:fund_activity, organisation: user.organisation) }

      it { is_expected.to permit_action(:show) }
      it { is_expected.to permit_new_and_create_actions }
      it { is_expected.to permit_edit_and_update_actions }
      it { is_expected.to forbid_action(:destroy) }

      it "includes activity in resolved scope" do
        resolved_scope = described_class::Scope.new(user, Activity.all).resolve
        expect(resolved_scope).to include(activity)
      end
    end

    context "when the activity is a programme" do
      let(:activity) { create(:programme_activity, organisation: user.organisation) }

      it { is_expected.to permit_action(:show) }
      it { is_expected.to permit_new_and_create_actions }
      it { is_expected.to permit_edit_and_update_actions }
      it { is_expected.to forbid_action(:destroy) }

      it "includes activity in resolved scope" do
        resolved_scope = described_class::Scope.new(user, Activity.all).resolve
        expect(resolved_scope).to include(activity)
      end
    end

    context "when the activity is a project" do
      let(:activity) { create(:project_activity) }

      it { is_expected.to permit_action(:show) }
      it { is_expected.to forbid_new_and_create_actions }
      it { is_expected.to forbid_edit_and_update_actions }
      it { is_expected.to forbid_action(:destroy) }

      it "includes activity in resolved scope" do
        resolved_scope = described_class::Scope.new(user, Activity.all).resolve
        expect(resolved_scope).to include(activity)
      end
    end
  end

  context "when the user does NOT belong to BEIS" do
    let(:user) { build_stubbed(:delivery_partner_user) }

    context "when the activity is a fund" do
      let(:activity) { create(:fund_activity, organisation: user.organisation) }

      it { is_expected.to forbid_action(:show) }
      it { is_expected.to forbid_new_and_create_actions }
      it { is_expected.to forbid_edit_and_update_actions }
      it { is_expected.to forbid_action(:destroy) }

      it "includes does not include the activity in resolved scope" do
        resolved_scope = described_class::Scope.new(user, Activity.all).resolve
        expect(resolved_scope).to be_empty
      end
    end

    context "when the activity is a programme" do
      let(:activity) { create(:programme_activity, organisation: user.organisation) }

      it { is_expected.to permit_action(:show) }
      it { is_expected.to forbid_new_and_create_actions }
      it { is_expected.to forbid_edit_and_update_actions }
      it { is_expected.to forbid_action(:destroy) }

      it "includes activity in resolved scope" do
        resolved_scope = described_class::Scope.new(user, Activity.all).resolve
        expect(resolved_scope).to include(activity)
      end
    end

    context "when the activity is a project" do
      let(:activity) { create(:project_activity) }

      it { is_expected.to permit_action(:show) }
      it { is_expected.to permit_new_and_create_actions }
      it { is_expected.to permit_edit_and_update_actions }
      it { is_expected.to forbid_action(:destroy) }

      it "includes activity in resolved scope" do
        resolved_scope = described_class::Scope.new(user, Activity.all).resolve
        expect(resolved_scope).to include(activity)
      end
    end
  end
end
