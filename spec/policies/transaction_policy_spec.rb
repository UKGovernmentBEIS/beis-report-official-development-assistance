require "rails_helper"

RSpec.describe TransactionPolicy do
  let(:user) { create(:beis_user) }
  let(:activity) { create(:activity, organisation: user.organisation) }
  let(:transaction) { create(:transaction, parent_activity: activity) }

  subject { described_class.new(user, transaction) }

  describe "#create?" do
    context "when there is no submission to attach this transaction to" do
      context "when the user belongs to the authoring organisation" do
        let(:transaction) { create(:transaction, parent_activity: activity) }
        it { is_expected.to forbid_action(:create) }
      end
    end

    context "when there is a submission to attach this transaction to" do
      before do
        _submission = create(:submission, :active, organisation: user.organisation, fund: activity)
      end

      context "when the user belongs to the authoring organisation" do
        let(:transaction) { create(:transaction, parent_activity: activity) }
        it { is_expected.to permit_action(:create) }
      end

      context "when the user does NOT belong to the authoring organisation" do
        let(:another_organisation) { create(:organisation) }
        let(:activity) { create(:activity, organisation: another_organisation) }
        let(:transaction) { create(:transaction, parent_activity: activity) }
        it { is_expected.to forbid_action(:create) }
      end
    end
  end

  describe "#update?" do
    let(:submission) { create(:submission, :active, organisation: user.organisation, fund: activity) }

    context "when the user belongs to the authoring organisation" do
      let(:transaction) { create(:transaction, parent_activity: activity, submission: submission) }
      it { is_expected.to permit_action(:update) }
    end

    context "when the user does NOT belong to the authoring organisation" do
      let(:another_organisation) { create(:organisation) }
      let(:activity) { create(:activity, organisation: another_organisation) }
      let(:transaction) { create(:transaction, parent_activity: activity) }
      it { is_expected.to forbid_action(:update) }
    end

    context "when the transaction is associated to an active submission" do
      let(:submission) { create(:submission, :active, organisation: activity.organisation, fund: activity) }
      let(:transaction) { create(:transaction, parent_activity: activity, submission: submission) }
      it { is_expected.to permit_action(:update) }
    end

    context "when the transaction is associated to an inactive submission" do
      let(:submission) { create(:submission, organisation: activity.organisation, fund: activity) }
      let(:transaction) { create(:transaction, parent_activity: activity, submission: submission) }
      it { is_expected.to forbid_action(:update) }
    end
  end

  describe "#destroy?" do
    let(:transaction) { create(:transaction, parent_activity: activity) }
    it { is_expected.to forbid_action(:destroy) }
  end
end
