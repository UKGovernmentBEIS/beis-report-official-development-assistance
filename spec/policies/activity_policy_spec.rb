require "rails_helper"

RSpec.describe ActivityPolicy do
  let!(:report) { create(:report, organisation: user.organisation, fund: activity.associated_fund, state: :approved) }
  let(:user) { build_stubbed(:beis_user) }

  subject { described_class.new(user, activity) }

  context "as a BEIS user" do
    let(:user) { create(:beis_user) }

    context "when the activity is a fund" do
      let(:activity) { create(:fund_activity, organisation: user.organisation, extending_organisation: user.organisation) }

      it { is_expected.to permit_action(:show) }
      it { is_expected.to permit_action(:create) }
      it { is_expected.to permit_action(:edit) }
      it { is_expected.to permit_action(:update) }

      it { is_expected.to forbid_action(:destroy) }
      it { is_expected.to forbid_action(:redact_from_iati) }

      it { is_expected.to permit_action(:create_child) }
      it { is_expected.to permit_action(:create_transfer) }
    end

    context "when the activity is a programme" do
      let(:activity) { create(:programme_activity, organisation: user.organisation) }

      it { is_expected.to permit_action(:show) }
      it { is_expected.to permit_action(:create) }
      it { is_expected.to permit_action(:edit) }
      it { is_expected.to permit_action(:update) }

      it { is_expected.to forbid_action(:destroy) }
      it { is_expected.to forbid_action(:redact_from_iati) }

      it { is_expected.to forbid_action(:create_child) }
      it { is_expected.to permit_action(:create_transfer) }
    end

    context "when the activity is a project" do
      let(:activity) { create(:project_activity) }

      it { is_expected.to permit_action(:show) }
      it { is_expected.to permit_action(:redact_from_iati) }

      it { is_expected.to forbid_action(:create) }
      it { is_expected.to forbid_action(:edit) }
      it { is_expected.to forbid_action(:update) }
      it { is_expected.to forbid_action(:destroy) }

      it { is_expected.to forbid_action(:create_child) }
      it { is_expected.to forbid_action(:create_transfer) }
    end

    context "when the activity is a third-party project" do
      let(:activity) { create(:third_party_project_activity) }

      it { is_expected.to permit_action(:show) }
      it { is_expected.to permit_action(:redact_from_iati) }

      it { is_expected.to forbid_action(:create) }
      it { is_expected.to forbid_action(:edit) }
      it { is_expected.to forbid_action(:update) }
      it { is_expected.to forbid_action(:destroy) }

      it { is_expected.to forbid_action(:create_child) }
      it { is_expected.to forbid_action(:create_transfer) }
    end
  end

  context "as a Delivery partner user" do
    let(:user) { create(:delivery_partner_user) }

    context "when the activity is a fund" do
      let(:activity) { create(:fund_activity) }

      it { is_expected.to forbid_action(:show) }
      it { is_expected.to forbid_action(:create) }
      it { is_expected.to forbid_action(:edit) }
      it { is_expected.to forbid_action(:update) }
      it { is_expected.to forbid_action(:destroy) }
      it { is_expected.to forbid_action(:redact_from_iati) }

      it { is_expected.to forbid_action(:create_child) }
      it { is_expected.to forbid_action(:create_transfer) }
    end

    context "when the activity is a programme" do
      let(:activity) { create(:programme_activity) }

      context "and the users organisation is not the extending organisation" do
        it { is_expected.to forbid_action(:show) }
        it { is_expected.to forbid_action(:create) }
        it { is_expected.to forbid_action(:edit) }
        it { is_expected.to forbid_action(:update) }
        it { is_expected.to forbid_action(:destroy) }
        it { is_expected.to forbid_action(:redact_from_iati) }

        it { is_expected.to forbid_action(:create_child) }
        it { is_expected.to forbid_action(:create_transfer) }
      end

      context "and the users organisation is the extending organisation" do
        before do
          activity.update(extending_organisation: user.organisation)
        end

        it { is_expected.to permit_action(:show) }

        it { is_expected.to forbid_action(:create) }
        it { is_expected.to forbid_action(:edit) }
        it { is_expected.to forbid_action(:update) }
        it { is_expected.to forbid_action(:destroy) }
        it { is_expected.to forbid_action(:redact_from_iati) }

        it { is_expected.to forbid_action(:create_child) }
        it { is_expected.to forbid_action(:create_transfer) }

        context "and there is an editable report for the users organisation" do
          before do
            report.update(state: :active)
          end

          it { is_expected.to permit_action(:create_child) }
          it { is_expected.to forbid_action(:create_transfer) }
        end
      end
    end

    context "when the activity is a project" do
      let(:activity) { create(:project_activity) }

      context "and the users organisation is not the extending organisation" do
        it { is_expected.to forbid_action(:show) }
        it { is_expected.to forbid_action(:create) }
        it { is_expected.to forbid_action(:edit) }
        it { is_expected.to forbid_action(:update) }
        it { is_expected.to forbid_action(:destroy) }
        it { is_expected.to forbid_action(:redact_from_iati) }

        it { is_expected.to forbid_action(:create_child) }
        it { is_expected.to forbid_action(:create_transfer) }
      end

      context "and the users organisation is the extending organisation" do
        before do
          activity.update(organisation: user.organisation, extending_organisation: user.organisation)
        end

        context "and there is no editable report for the users organisation" do
          it { is_expected.to permit_action(:show) }

          it { is_expected.to forbid_action(:create) }
          it { is_expected.to forbid_action(:edit) }
          it { is_expected.to forbid_action(:update) }
          it { is_expected.to forbid_action(:destroy) }
          it { is_expected.to forbid_action(:redact_from_iati) }

          it { is_expected.to forbid_action(:create_child) }
          it { is_expected.to forbid_action(:create_transfer) }
        end

        context "and there is an editable report for the users organisation" do
          before do
            report.update(state: :active)
          end

          it { is_expected.to permit_action(:show) }
          it { is_expected.to permit_action(:create) }
          it { is_expected.to permit_action(:edit) }
          it { is_expected.to permit_action(:update) }

          it { is_expected.to forbid_action(:destroy) }
          it { is_expected.to forbid_action(:redact_from_iati) }

          it { is_expected.to permit_action(:create_child) }
          it { is_expected.to permit_action(:create_transfer) }
        end
      end
    end

    context "when the activity is a third-party project" do
      let(:activity) { create(:third_party_project_activity) }

      context "and the users organisation is not the extending organisation" do
        it { is_expected.to forbid_action(:show) }
        it { is_expected.to forbid_action(:create) }
        it { is_expected.to forbid_action(:edit) }
        it { is_expected.to forbid_action(:update) }
        it { is_expected.to forbid_action(:destroy) }
        it { is_expected.to forbid_action(:redact_from_iati) }

        it { is_expected.to forbid_action(:create_child) }
        it { is_expected.to forbid_action(:create_transfer) }
      end

      context "and the users organisation is the extending organisation" do
        before do
          activity.update(organisation: user.organisation, extending_organisation: user.organisation)
        end

        context "and there is no editable report for the users organisation" do
          it { is_expected.to permit_action(:show) }

          it { is_expected.to forbid_action(:create) }
          it { is_expected.to forbid_action(:edit) }
          it { is_expected.to forbid_action(:update) }
          it { is_expected.to forbid_action(:destroy) }
          it { is_expected.to forbid_action(:redact_from_iati) }

          it { is_expected.to forbid_action(:create_child) }
          it { is_expected.to forbid_action(:create_transfer) }
        end

        context "and there is an editable report for the users organisation" do
          before do
            report.update(state: :active)
          end

          it { is_expected.to permit_action(:show) }
          it { is_expected.to permit_action(:create) }
          it { is_expected.to permit_action(:edit) }
          it { is_expected.to permit_action(:update) }

          it { is_expected.to forbid_action(:destroy) }
          it { is_expected.to forbid_action(:redact_from_iati) }

          it { is_expected.to forbid_action(:create_child) }
          it { is_expected.to permit_action(:create_transfer) }
        end
      end
    end
  end
end
