require "rails_helper"

RSpec.describe BudgetPolicy do
  let(:activity) { create(:activity) }
  let(:budget) { create(:budget, activity: activity) }
  subject { described_class.new(user, budget) }

  context "as an administrator" do
    let(:user) { build_stubbed(:administrator) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_new_and_create_actions }
    it { is_expected.to permit_edit_and_update_actions }
    it { is_expected.to permit_action(:destroy) }

    it "includes budget in resolved scope" do
      resolved_scope = described_class::Scope.new(user, Budget.all).resolve
      expect(resolved_scope).to include(budget)
    end
  end

  context "as a fund manager" do
    let(:user) { build_stubbed(:fund_manager) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_new_and_create_actions }
    it { is_expected.to permit_edit_and_update_actions }
    it { is_expected.to permit_action(:destroy) }

    it "includes budget in resolved scope" do
      resolved_scope = described_class::Scope.new(user, Budget.all).resolve
      expect(resolved_scope).to include(budget)
    end
  end

  context "as a delivery partner" do
    let(:user) { build_stubbed(:delivery_partner) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to forbid_action(:show) }
    it { is_expected.to forbid_new_and_create_actions }
    it { is_expected.to forbid_edit_and_update_actions }
    it { is_expected.to forbid_action(:destroy) }

    it "does not include include budget in resolved scope" do
      resolved_scope = described_class::Scope.new(user, Budget.all).resolve
      expect(resolved_scope).not_to include(budget)
    end
  end
end
