require "rails_helper"

RSpec.describe BudgetPolicy do
  let(:user) { create(:administrator) }
  let(:activity) { create(:activity, organisation: user.organisation) }
  let(:other_activity) { create(:activity, organisation: create(:organisation)) }
  let(:budget) { create(:budget, activity: activity) }
  let!(:other_budget) { create(:budget, activity: other_activity) }

  subject { described_class.new(user, budget) }

  context "as a BEIS user" do
    let(:user) { create(:beis_user) }

    context "when the activity is a fund" do
      let(:activity) { create(:fund_activity, organisation: user.organisation) }
      subject { described_class.new(user, budget) }

      it { is_expected.to permit_action(:index) }
      it { is_expected.to permit_action(:show) }
      it { is_expected.to permit_new_and_create_actions }
      it { is_expected.to permit_edit_and_update_actions }
      it { is_expected.to forbid_action(:destroy) }
    end

    context "when the activity is a programme" do
      let(:activity) { create(:programme_activity, organisation: user.organisation) }
      subject { described_class.new(user, budget) }

      it { is_expected.to permit_action(:index) }
      it { is_expected.to permit_action(:show) }
      it { is_expected.to permit_new_and_create_actions }
      it { is_expected.to permit_edit_and_update_actions }
      it { is_expected.to forbid_action(:destroy) }
    end

    context "when the activity is a project" do
      let(:activity) { create(:project_activity, organisation: user.organisation) }
      subject { described_class.new(user, budget) }

      it { is_expected.to permit_action(:index) }
      it { is_expected.to permit_action(:show) }
      it { is_expected.to forbid_new_and_create_actions }
      it { is_expected.to forbid_edit_and_update_actions }
      it { is_expected.to forbid_action(:destroy) }
    end

    it "includes all budgets in the resolved scope" do
      resolved_scope = described_class::Scope.new(user, Budget.all).resolve
      expect(resolved_scope).to include(budget)
      expect(resolved_scope).to include(other_budget)
    end
  end

  context "as a non-BEIS user" do
    let(:user) { build_stubbed(:delivery_partner_user) }

    context "when the activity is a fund" do
      let(:activity) { create(:fund_activity, organisation: user.organisation) }
      subject { described_class.new(user, budget) }

      it { is_expected.to permit_action(:index) }
      it { is_expected.to permit_action(:show) }
      it { is_expected.to forbid_new_and_create_actions }
      it { is_expected.to forbid_edit_and_update_actions }
      it { is_expected.to forbid_action(:destroy) }
    end

    context "when the activity is a programme" do
      let(:activity) { create(:programme_activity, organisation: user.organisation) }
      subject { described_class.new(user, budget) }

      it { is_expected.to permit_action(:index) }
      it { is_expected.to permit_action(:show) }
      it { is_expected.to forbid_new_and_create_actions }
      it { is_expected.to forbid_edit_and_update_actions }
      it { is_expected.to forbid_action(:destroy) }
    end

    context "when the activity is a project" do
      let(:activity) { create(:project_activity, organisation: user.organisation) }
      subject { described_class.new(user, budget) }

      it { is_expected.to permit_action(:index) }
      it { is_expected.to permit_action(:show) }
      it { is_expected.to permit_new_and_create_actions }
      it { is_expected.to permit_edit_and_update_actions }
      it { is_expected.to forbid_action(:destroy) }
    end

    it "includes only budgets that belong to the user's organisation in resolved scope" do
      resolved_scope = described_class::Scope.new(user, Budget.all).resolve
      expect(resolved_scope).to include(budget)
      expect(resolved_scope).to_not include(other_budget)
    end
  end
end
