require "rails_helper"

RSpec.describe BudgetPolicy do
  let(:user) { create(:beis_user) }
  let(:activity) { create(:activity, organisation: user.organisation) }
  let(:budget) { create(:budget, parent_activity: activity) }

  subject { described_class.new(user, budget) }

  describe "#create?" do
    context "when the user belongs to the authoring organisation" do
      let(:budget) { create(:budget, parent_activity: activity) }
      it { is_expected.to permit_action(:create) }
    end

    context "when the user does NOT belong to the authoring organisation" do
      let(:another_organisation) { create(:organisation) }
      let(:activity) { create(:activity, organisation: another_organisation) }
      let(:budget) { create(:budget, parent_activity: activity) }
      it { is_expected.to forbid_action(:create) }
    end
  end

  describe "#update?" do
    context "when the user belongs to the authoring organisation" do
      let(:budget) { create(:budget, parent_activity: activity) }
      it { is_expected.to permit_action(:update) }
    end

    context "when the user does NOT belong to the authoring organisation" do
      let(:another_organisation) { create(:organisation) }
      let(:activity) { create(:activity, organisation: another_organisation) }
      let(:budget) { create(:budget, parent_activity: activity) }
      it { is_expected.to forbid_action(:update) }
    end
  end

  describe "#destroy?" do
    let(:budget) { create(:budget, parent_activity: activity) }
    it { is_expected.to forbid_action(:destroy) }
  end
end
