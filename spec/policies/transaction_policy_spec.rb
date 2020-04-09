require "rails_helper"

RSpec.describe TransactionPolicy do
  let(:user) { create(:administrator) }
  let(:transaction) { create(:transaction, parent_activity: activity) }
  let(:activity) { create(:activity, organisation: user.organisation) }
  let(:other_activity) { create(:activity, organisation: create(:organisation)) }
  let!(:other_transaction) { create(:transaction, parent_activity: other_activity) }

  context "as a BEIS user" do
    let(:user) { create(:beis_user) }

    context "when the activity is a fund" do
      let(:activity) { create(:fund_activity, organisation: user.organisation) }
      subject { described_class.new(user, transaction) }

      it { is_expected.to permit_action(:index) }
      it { is_expected.to permit_action(:show) }
      it { is_expected.to permit_new_and_create_actions }
      it { is_expected.to permit_edit_and_update_actions }
      it { is_expected.to forbid_action(:destroy) }
    end

    context "when the activity is a programme" do
      let(:activity) { create(:programme_activity, organisation: user.organisation) }
      subject { described_class.new(user, transaction) }

      it { is_expected.to permit_action(:index) }
      it { is_expected.to permit_action(:show) }
      it { is_expected.to permit_new_and_create_actions }
      it { is_expected.to permit_edit_and_update_actions }
      it { is_expected.to forbid_action(:destroy) }
    end

    context "when the activity is a project" do
      let(:activity) { create(:project_activity, organisation: user.organisation) }
      subject { described_class.new(user, transaction) }

      it { is_expected.to permit_action(:index) }
      it { is_expected.to permit_action(:show) }
      it { is_expected.to forbid_new_and_create_actions }
      it { is_expected.to forbid_edit_and_update_actions }
      it { is_expected.to forbid_action(:destroy) }
    end

    it "includes all transactions in resolved scope" do
      resolved_scope = described_class::Scope.new(user, Transaction.all).resolve
      expect(resolved_scope).to include(transaction)
      expect(resolved_scope).to include(other_transaction)
    end
  end

  context "as a delivery partner user" do
    let(:user) { build_stubbed(:delivery_partner_user) }

    context "when the activity is a fund" do
      let(:activity) { create(:fund_activity, organisation: user.organisation) }
      subject { described_class.new(user, transaction) }

      it { is_expected.to permit_action(:index) }
      it { is_expected.to permit_action(:show) }
      it { is_expected.to forbid_new_and_create_actions }
      it { is_expected.to forbid_edit_and_update_actions }
      it { is_expected.to forbid_action(:destroy) }
    end

    context "when the activity is a programme" do
      let(:activity) { create(:programme_activity, organisation: user.organisation) }
      subject { described_class.new(user, transaction) }

      it { is_expected.to permit_action(:index) }
      it { is_expected.to permit_action(:show) }
      it { is_expected.to forbid_new_and_create_actions }
      it { is_expected.to forbid_edit_and_update_actions }
      it { is_expected.to forbid_action(:destroy) }
    end

    context "when the activity is a project" do
      let(:activity) { create(:project_activity, organisation: user.organisation) }
      subject { described_class.new(user, transaction) }

      it { is_expected.to permit_action(:index) }
      it { is_expected.to permit_action(:show) }
      it { is_expected.to permit_new_and_create_actions }
      it { is_expected.to permit_edit_and_update_actions }
      it { is_expected.to forbid_action(:destroy) }
    end

    it "includes only transactions the belong to the user's organisation in resolved scope" do
      resolved_scope = described_class::Scope.new(user, Transaction.all).resolve
      expect(resolved_scope).to include(transaction)
      expect(resolved_scope).to_not include(other_transaction)
    end
  end
end
