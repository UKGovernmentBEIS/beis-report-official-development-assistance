require "rails_helper"

RSpec.describe ReportPolicy do
  let(:organisation) { create(:delivery_partner_organisation) }
  let(:another_organistion) { create(:delivery_partner_organisation) }
  let!(:report) { create(:report, organisation: organisation) }
  let!(:another_report) { create(:report, organisation: another_organistion) }

  subject { described_class.new(user, report) }

  context "as a user that belongs to BEIS" do
    let(:user) { build_stubbed(:beis_user) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_new_and_create_actions }
    it { is_expected.to permit_edit_and_update_actions }
    it { is_expected.to forbid_action(:destroy) }
    it { is_expected.to permit_action(:download) }
    it { is_expected.to forbid_action(:submit) }

    it "includes all reports in the resolved scope" do
      resolved_scope = described_class::Scope.new(user, Report).resolve
      expect(resolved_scope).to include report, another_report
    end
  end

  context "as a user that does NOT belong to BEIS" do
    let(:user) { build_stubbed(:delivery_partner_user, organisation: organisation) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to forbid_new_and_create_actions }
    it { is_expected.to forbid_new_and_create_actions }
    it { is_expected.to forbid_action(:destroy) }

    context "when the report belongs to the user's organisation" do
      let(:report) { create(:report, organisation: user.organisation) }
      it { is_expected.to permit_action(:download) }
      it { is_expected.to permit_action(:show) }
      it { is_expected.to permit_action(:submit) }
      it { is_expected.to permit_action(:complete) }
    end

    context "when the report does not belong to the user's organisation" do
      let(:report) { create(:report, organisation: create(:organisation)) }
      it { is_expected.to forbid_action(:download) }
      it { is_expected.to forbid_action(:show) }
      it { is_expected.to forbid_action(:submit) }
      it { is_expected.to forbid_action(:complete) }
    end

    context "when the report is already submitted" do
      let(:report) { create(:report, state: :submitted, organisation: create(:organisation)) }
      it { is_expected.to forbid_action(:submit) }
    end

    it "includes only reports that the users organisation is reporting in the resolved scope" do
      resolved_scope = described_class::Scope.new(user, Report).resolve
      expect(resolved_scope).to contain_exactly report
    end

    context "when the report does not belong to the delivery partner users organisation" do
      let(:report) { create(:report, :active, organisation: another_organistion) }

      it { is_expected.to forbid_action(:show) }
    end
  end
end
