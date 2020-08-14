require "rails_helper"

RSpec.describe PlannedDisbursementPolicy do
  let(:user) { create(:beis_user) }
  let(:activity) { create(:project_activity, :with_report, organisation: user.organisation) }
  let(:planned_disbursement) { create(:planned_disbursement, parent_activity: activity) }

  subject { described_class.new(user, planned_disbursement) }

  describe "#create?" do
    context "when there is no active Report to attach this planned disbursement to" do
      let(:activity) { create(:project_activity, organisation: user.organisation) }
      it { is_expected.to forbid_action(:create) }
    end

    context "when there is an active Report to attach this planned disbursement to" do
      context "when the parent is a fund" do
        let(:activity) { create(:fund_activity, :with_report, organisation: user.organisation) }
        it { is_expected.to forbid_action(:create) }
      end

      context "when the parent is a programme" do
        let(:activity) { create(:programme_activity, :with_report, organisation: user.organisation) }
        it { is_expected.to forbid_action(:create) }
      end

      context "when the parent is a project" do
        let(:activity) { create(:project_activity, :with_report, organisation: user.organisation) }
        it { is_expected.to permit_action(:create) }
      end

      context "when the parent is a third_party_project" do
        let(:activity) { create(:third_party_project_activity, :with_report, organisation: user.organisation) }
        it { is_expected.to permit_action(:create) }
      end

      context "when the user belongs to the authoring organisation" do
        let(:planned_disbursement) { create(:planned_disbursement, parent_activity: activity) }
        it { is_expected.to permit_action(:create) }
      end

      context "when the user does NOT belong to the authoring organisation" do
        let(:another_organisation) { create(:organisation) }
        let(:activity) { create(:activity, organisation: another_organisation) }
        let(:planned_disbursement) { create(:planned_disbursement, parent_activity: activity) }
        it { is_expected.to forbid_action(:create) }
      end
    end
  end

  describe "#update?" do
    context "when there is no active Report to attach this planned disbursement to" do
      let(:activity) { create(:project_activity, organisation: user.organisation) }
      it { is_expected.to forbid_action(:update) }
    end

    context "when there is an active Report to attach this planned disbursement to" do
      context "when the parent is a fund" do
        let(:activity) { create(:fund_activity, :with_report, organisation: user.organisation) }
        it { is_expected.to forbid_action(:update) }
      end

      context "when the parent is a programme" do
        let(:activity) { create(:programme_activity, :with_report, organisation: user.organisation) }
        it { is_expected.to forbid_action(:update) }
      end

      context "when the parent is a project" do
        let(:activity) { create(:project_activity, :with_report, organisation: user.organisation) }
        it { is_expected.to permit_action(:update) }
      end

      context "when the parent is a third_party_project" do
        let(:activity) { create(:third_party_project_activity, :with_report, organisation: user.organisation) }
        it { is_expected.to permit_action(:update) }
      end

      context "when the user belongs to the authoring organisation" do
        let(:planned_disbursement) { create(:planned_disbursement, parent_activity: activity) }
        it { is_expected.to permit_action(:update) }
      end

      context "when the user does NOT belong to the authoring organisation" do
        let(:another_organisation) { create(:organisation) }
        let(:activity) { create(:activity, organisation: another_organisation) }
        let(:planned_disbursement) { create(:planned_disbursement, parent_activity: activity) }
        it { is_expected.to forbid_action(:update) }
      end
    end
  end

  describe "#destroy?" do
    let(:planned_disbursement) { create(:planned_disbursement, parent_activity: activity) }
    it { is_expected.to forbid_action(:destroy) }
  end
end
