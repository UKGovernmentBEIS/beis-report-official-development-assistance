require "rails_helper"

RSpec.describe ActivityPolicy do
  let(:organisation) { create(:organisation) }

  subject { described_class.new(user, activity) }

  context "for a fund" do
    let(:fund) { create(:fund, organisation: organisation) }
    let(:activity) { create(:activity, hierarchy: fund) }

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

      it { is_expected.to permit_action(:index) }
      it { is_expected.to forbid_action(:show) }
      it { is_expected.to forbid_new_and_create_actions }
      it { is_expected.to forbid_edit_and_update_actions }
      it { is_expected.to forbid_action(:destroy) }

      it "does not include activity in resolved scope" do
        resolved_scope = described_class::Scope.new(user, Activity.all).resolve
        expect(resolved_scope).not_to include(activity)
      end
    end
  end
end
