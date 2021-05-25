require "rails_helper"

RSpec.describe ReportPolicy do
  subject { described_class.new(user, report) }

  context "as a BEIS user" do
    let(:user) { build_stubbed(:beis_user) }
    let(:report) { create(:report) }

    it "includes all reports in the resolved scope" do
      report = create(:report)
      another_report = create(:report)
      resolved_scope = described_class::Scope.new(user, Report).resolve

      expect(resolved_scope).to include report, another_report
    end

    context "when the report is inactive" do
      before { report.update(state: :inactive) }

      it { is_expected.to permit_action(:update) }
      it { is_expected.to permit_action(:index) }
      it { is_expected.to permit_action(:show) }
      it { is_expected.to permit_action(:download) }
      it { is_expected.to permit_action(:change_state) }
      it { is_expected.to permit_action(:activate) }

      it { is_expected.to forbid_action(:create) }
      it { is_expected.to forbid_action(:destroy) }

      it { is_expected.to forbid_action(:submit) }
      it { is_expected.to forbid_action(:review) }
      it { is_expected.to forbid_action(:request_changes) }
      it { is_expected.to forbid_action(:approve) }
      it { is_expected.to forbid_action(:upload) }
    end

    context "when the report is active" do
      before { report.update(state: :active) }

      it { is_expected.to forbid_action(:change_state) }
      it { is_expected.to forbid_action(:activate) }
      it { is_expected.to forbid_action(:submit) }
      it { is_expected.to forbid_action(:request_changes) }
      it { is_expected.to forbid_action(:review) }
      it { is_expected.to forbid_action(:approve) }
      it { is_expected.to forbid_action(:upload) }
    end

    context "when the report is submitted" do
      before { report.update(state: :submitted) }

      it { is_expected.to permit_action(:change_state) }
      it { is_expected.to permit_action(:review) }

      it { is_expected.to forbid_action(:activate) }
      it { is_expected.to forbid_action(:submit) }
      it { is_expected.to forbid_action(:request_changes) }
      it { is_expected.to forbid_action(:approve) }
      it { is_expected.to forbid_action(:upload) }
    end

    context "when the report is in review" do
      before { report.update(state: :in_review) }

      it { is_expected.to permit_action(:change_state) }
      it { is_expected.to permit_action(:request_changes) }
      it { is_expected.to permit_action(:approve) }

      it { is_expected.to forbid_action(:activate) }
      it { is_expected.to forbid_action(:submit) }
      it { is_expected.to forbid_action(:review) }
      it { is_expected.to forbid_action(:upload) }
    end

    context "when the report is awaiting changes" do
      before { report.update(state: :awaiting_changes) }

      it { is_expected.to forbid_action(:change_state) }
      it { is_expected.to forbid_action(:activate) }
      it { is_expected.to forbid_action(:submit) }
      it { is_expected.to forbid_action(:request_changes) }
      it { is_expected.to forbid_action(:review) }
      it { is_expected.to forbid_action(:approve) }
      it { is_expected.to forbid_action(:upload) }
    end

    context "when the report is approved" do
      before { report.update(state: :approved) }

      it { is_expected.to forbid_action(:change_state) }
      it { is_expected.to forbid_action(:activate) }
      it { is_expected.to forbid_action(:submit) }
      it { is_expected.to forbid_action(:request_changes) }
      it { is_expected.to forbid_action(:review) }
      it { is_expected.to forbid_action(:approve) }
      it { is_expected.to forbid_action(:upload) }
    end
  end

  context "as a Delivery partner user" do
    let(:user) { build_stubbed(:delivery_partner_user) }

    it "includes only reports that the users organisation is reporting in the resolved scope" do
      report = create(:report, organisation: user.organisation)
      _another_report = create(:report)
      resolved_scope = described_class::Scope.new(user, Report).resolve

      expect(resolved_scope).to contain_exactly report
    end

    context "when the report does not belong to the users organisation" do
      let(:report) { create(:report) }

      it { is_expected.to forbid_action(:update) }
      it { is_expected.to forbid_action(:create) }
      it { is_expected.to forbid_action(:change_state) }
      it { is_expected.to forbid_action(:destroy) }
      it { is_expected.to forbid_action(:activate) }
      it { is_expected.to forbid_action(:submit) }
      it { is_expected.to forbid_action(:review) }
      it { is_expected.to forbid_action(:request_changes) }
      it { is_expected.to forbid_action(:approve) }
      it { is_expected.to forbid_action(:upload) }

      it { is_expected.to permit_action(:index) }
    end

    context "when the report belongs to the users organisation" do
      let(:report) { create(:report, organisation: user.organisation) }

      context "when the report is inactive" do
        before { report.update(state: :inactive) }

        it { is_expected.to forbid_action(:show) }
        it { is_expected.to forbid_action(:download) }
        it { is_expected.to forbid_action(:change_state) }
        it { is_expected.to forbid_action(:destroy) }
        it { is_expected.to forbid_action(:activate) }
        it { is_expected.to forbid_action(:submit) }
        it { is_expected.to forbid_action(:review) }
        it { is_expected.to forbid_action(:request_changes) }
        it { is_expected.to forbid_action(:approve) }
        it { is_expected.to forbid_action(:upload) }
      end

      context "when the report is active" do
        before { report.update(state: :active) }

        it { is_expected.to permit_action(:show) }
        it { is_expected.to permit_action(:download) }
        it { is_expected.to permit_action(:change_state) }
        it { is_expected.to permit_action(:submit) }
        it { is_expected.to permit_action(:upload) }

        it { is_expected.to forbid_action(:activate) }
        it { is_expected.to forbid_action(:review) }
        it { is_expected.to forbid_action(:request_changes) }
        it { is_expected.to forbid_action(:approve) }
      end

      context "when the report is submitted" do
        before { report.update(state: :submitted) }

        it { is_expected.to permit_action(:show) }
        it { is_expected.to permit_action(:download) }

        it { is_expected.to forbid_action(:change_state) }
        it { is_expected.to forbid_action(:activate) }
        it { is_expected.to forbid_action(:submit) }
        it { is_expected.to forbid_action(:review) }
        it { is_expected.to forbid_action(:request_changes) }
        it { is_expected.to forbid_action(:approve) }
        it { is_expected.to forbid_action(:upload) }
      end

      context "when the report is in review" do
        before { report.update(state: :in_review) }

        it { is_expected.to permit_action(:show) }
        it { is_expected.to permit_action(:download) }

        it { is_expected.to forbid_action(:change_state) }
        it { is_expected.to forbid_action(:activate) }
        it { is_expected.to forbid_action(:submit) }
        it { is_expected.to forbid_action(:review) }
        it { is_expected.to forbid_action(:request_changes) }
        it { is_expected.to forbid_action(:approve) }
        it { is_expected.to forbid_action(:upload) }
      end

      context "when the report is awaiting changes" do
        before { report.update(state: :awaiting_changes) }

        it { is_expected.to permit_action(:show) }
        it { is_expected.to permit_action(:download) }
        it { is_expected.to permit_action(:change_state) }
        it { is_expected.to permit_action(:submit) }
        it { is_expected.to permit_action(:upload) }

        it { is_expected.to forbid_action(:activate) }
        it { is_expected.to forbid_action(:review) }
        it { is_expected.to forbid_action(:request_changes) }
        it { is_expected.to forbid_action(:approve) }
      end

      context "when the report is approved" do
        before { report.update(state: :approved) }

        it { is_expected.to permit_action(:show) }
        it { is_expected.to permit_action(:download) }

        it { is_expected.to forbid_action(:change_state) }
        it { is_expected.to forbid_action(:activate) }
        it { is_expected.to forbid_action(:submit) }
        it { is_expected.to forbid_action(:request_changes) }
        it { is_expected.to forbid_action(:review) }
        it { is_expected.to forbid_action(:approve) }
        it { is_expected.to forbid_action(:upload) }
      end
    end
  end
end
