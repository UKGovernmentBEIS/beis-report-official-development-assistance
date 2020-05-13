require "rails_helper"

RSpec.describe PlannedDisbursementPolicy do
  context "when the user is a beis user" do
    let(:beis_user) { create(:beis_user) }
    let(:delivery_partner_user) { create(:delivery_partner_user) }

    context "when the activity is a fund" do
      let(:activity) { create(:fund_activity, organisation: beis_user.organisation) }
      let(:planned_disbursement) { create(:planned_disbursement, parent_activity: activity) }
      subject { described_class.new(beis_user, planned_disbursement) }

      it { is_expected.to permit_action(:index) }
      it { is_expected.to permit_action(:show) }
      it { is_expected.to forbid_new_and_create_actions }
      it { is_expected.to forbid_edit_and_update_actions }
      it { is_expected.to forbid_action(:destroy) }
    end

    context "when the activity is a programme" do
      let(:activity) { create(:programme_activity, organisation: beis_user.organisation) }
      let(:planned_disbursement) { create(:planned_disbursement, parent_activity: activity) }
      subject { described_class.new(beis_user, planned_disbursement) }

      it { is_expected.to permit_action(:index) }
      it { is_expected.to permit_action(:show) }
      it { is_expected.to forbid_new_and_create_actions }
      it { is_expected.to forbid_edit_and_update_actions }
      it { is_expected.to forbid_action(:destroy) }
    end

    context "when the activity is a project" do
      let(:activity) { create(:project_activity, organisation: delivery_partner_user.organisation) }
      let(:planned_disbursement) { create(:planned_disbursement, parent_activity: activity) }
      subject { described_class.new(beis_user, planned_disbursement) }

      it { is_expected.to permit_action(:index) }
      it { is_expected.to permit_action(:show) }
      it { is_expected.to forbid_new_and_create_actions }
      it { is_expected.to forbid_edit_and_update_actions }
      it { is_expected.to forbid_action(:destroy) }
    end

    context "when the activity is a third-party project" do
      let(:activity) { create(:third_party_project_activity, organisation: delivery_partner_user.organisation) }
      let(:planned_disbursement) { create(:planned_disbursement, parent_activity: activity) }
      subject { described_class.new(beis_user, planned_disbursement) }

      it { is_expected.to permit_action(:index) }
      it { is_expected.to permit_action(:show) }
      it { is_expected.to forbid_new_and_create_actions }
      it { is_expected.to forbid_edit_and_update_actions }
      it { is_expected.to forbid_action(:destroy) }
    end

    it "includes all planned_disbursementis in the resolved scope" do
      activity = create(:activity, organisation: beis_user.organisation)
      planned_disbursement = create(:planned_disbursement, parent_activity: activity)
      other_planned_disbursement = create(:planned_disbursement, parent_activity: create(:activity))
      resolved_scope = described_class::Scope.new(beis_user, PlannedDisbursement.all).resolve

      expect(resolved_scope).to include(planned_disbursement)
      expect(resolved_scope).to include(other_planned_disbursement)
    end
  end

  context "when the user is a delivery partner user" do
    let(:delivery_partner_user) { create(:delivery_partner_user) }
    let(:beis_user) { create(:beis_user) }

    context "when the activity is a fund" do
      let(:activity) { create(:fund_activity, organisation: beis_user.organisation) }
      let(:planned_disbursement) { create(:planned_disbursement, parent_activity: activity) }
      subject { described_class.new(delivery_partner_user, planned_disbursement) }

      it { is_expected.to permit_action(:index) }
      it { is_expected.to permit_action(:show) }
      it { is_expected.to forbid_new_and_create_actions }
      it { is_expected.to forbid_edit_and_update_actions }
      it { is_expected.to forbid_action(:destroy) }
    end

    context "when the activity is a programme" do
      let(:activity) { create(:programme_activity, organisation: beis_user.organisation) }
      let(:planned_disbursement) { create(:planned_disbursement, parent_activity: activity) }
      subject { described_class.new(delivery_partner_user, planned_disbursement) }

      it { is_expected.to permit_action(:index) }
      it { is_expected.to permit_action(:show) }
      it { is_expected.to forbid_new_and_create_actions }
      it { is_expected.to forbid_edit_and_update_actions }
      it { is_expected.to forbid_action(:destroy) }
    end

    context "when the activity is a project" do
      let(:activity) { create(:project_activity, organisation: delivery_partner_user.organisation) }
      let(:planned_disbursement) { create(:planned_disbursement, parent_activity: activity) }
      subject { described_class.new(delivery_partner_user, planned_disbursement) }

      it { is_expected.to permit_action(:index) }
      it { is_expected.to permit_action(:show) }
      it { is_expected.to permit_new_and_create_actions }
      it { is_expected.to permit_edit_and_update_actions }
      it { is_expected.to forbid_action(:destroy) }
    end

    context "when the activity is a third party project" do
      let(:activity) { create(:third_party_project_activity, organisation: delivery_partner_user.organisation) }
      let(:planned_disbursement) { create(:planned_disbursement, parent_activity: activity) }
      subject { described_class.new(delivery_partner_user, planned_disbursement) }

      it { is_expected.to permit_action(:index) }
      it { is_expected.to permit_action(:show) }
      it { is_expected.to permit_new_and_create_actions }
      it { is_expected.to permit_edit_and_update_actions }
      it { is_expected.to forbid_action(:destroy) }
    end

    it "includes only planned_disbursements that belong to the user's organisation in resolved scope" do
      activity = create(:activity, organisation: delivery_partner_user.organisation)
      planned_disbursement = create(:planned_disbursement, parent_activity: activity)
      other_planned_disbursement = create(:planned_disbursement, parent_activity: create(:activity))
      resolved_scope = described_class::Scope.new(delivery_partner_user, PlannedDisbursement.all).resolve

      expect(resolved_scope).to include(planned_disbursement)
      expect(resolved_scope).to_not include(other_planned_disbursement)
    end
  end
end
