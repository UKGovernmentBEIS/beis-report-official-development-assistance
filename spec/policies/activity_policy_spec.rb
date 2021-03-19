require "rails_helper"

RSpec.describe ActivityPolicy do
  let(:report) { create(:report, organisation: user.organisation) }
  let(:user) { build_stubbed(:beis_user) }

  subject { described_class.new(user, activity) }

  context "as a BEIS user" do
    let(:user) { create(:beis_user) }
    let(:activity) { CreateActivity.new(organisation_id: user.organisation.id).call }

    it { is_expected.to permit_action(:create) }

    context "when the activity has no level" do
      let(:activity) { CreateActivity.new(organisation_id: create(:delivery_partner_organisation).id).call }

      context "and the activity does not belong to the same organisation as the user" do
        it { is_expected.to permit_action(:show) }

        it { is_expected.to forbid_action(:edit) }
        it { is_expected.to forbid_action(:update) }
        it { is_expected.to forbid_action(:destroy) }
      end

      context "and the activity belongs to the same organisation as the user" do
        before do
          activity.update(organisation: user.organisation)
        end

        it { is_expected.to permit_action(:show) }
        it { is_expected.to permit_action(:edit) }
        it { is_expected.to permit_action(:update) }

        it { is_expected.to forbid_action(:destroy) }
      end
    end

    context "when the activity is a fund" do
      let(:activity) { create(:fund_activity, organisation: user.organisation) }

      it { is_expected.to permit_action(:show) }
      it { is_expected.to permit_action(:create) }
      it { is_expected.to permit_action(:edit) }
      it { is_expected.to permit_action(:update) }

      it { is_expected.to forbid_action(:destroy) }
      it { is_expected.to forbid_action(:redact_from_iati) }
    end

    context "when the activity is a programme" do
      let(:activity) { create(:programme_activity, organisation: user.organisation) }

      it { is_expected.to permit_action(:show) }
      it { is_expected.to permit_action(:create) }
      it { is_expected.to permit_action(:edit) }
      it { is_expected.to permit_action(:update) }

      it { is_expected.to forbid_action(:destroy) }
      it { is_expected.to forbid_action(:redact_from_iati) }
    end

    context "when the activity is a project" do
      let(:activity) { create(:project_activity) }

      it { is_expected.to permit_action(:show) }
      it { is_expected.to permit_action(:redact_from_iati) }

      it { is_expected.to forbid_action(:create) }
      it { is_expected.to forbid_action(:edit) }
      it { is_expected.to forbid_action(:update) }
      it { is_expected.to forbid_action(:destroy) }
    end

    context "when the activity is a third-party project" do
      let(:activity) { create(:third_party_project_activity) }

      it { is_expected.to permit_action(:show) }
      it { is_expected.to permit_action(:redact_from_iati) }

      it { is_expected.to forbid_action(:create) }
      it { is_expected.to forbid_action(:edit) }
      it { is_expected.to forbid_action(:update) }
      it { is_expected.to forbid_action(:destroy) }
    end
  end

  context "as a Delivery partner user" do
    let(:user) { create(:delivery_partner_user) }

    context "when the activity has no level" do
      let(:activity) { create(:activity, :at_identifier_step, level: nil) }

      context "and does not belong to the same organisation as the user" do
        it { is_expected.to forbid_action(:edit) }
        it { is_expected.to forbid_action(:update) }
        it { is_expected.to forbid_action(:destroy) }
      end

      context "and belongs to the same organisation as the user" do
        before do
          activity.update(organisation: user.organisation)
        end

        it { is_expected.to permit_action(:show) }
        it { is_expected.to permit_action(:edit) }
        it { is_expected.to permit_action(:update) }

        it { is_expected.to forbid_action(:destroy) }
      end
    end

    context "when the activity has a level but no parent" do
      let(:activity) { create(:activity, :at_identifier_step, level: :project, parent: nil) }

      context "and does not belong to the same organisation as the user" do
        it { is_expected.to forbid_action(:edit) }
        it { is_expected.to forbid_action(:update) }
        it { is_expected.to forbid_action(:destroy) }
      end

      context "and belongs to the same organisation as the user" do
        before do
          activity.update(organisation: user.organisation)
        end

        it { is_expected.to permit_action(:show) }
        it { is_expected.to permit_action(:edit) }
        it { is_expected.to permit_action(:update) }

        it { is_expected.to forbid_action(:destroy) }
      end
    end

    context "when the activity is a fund" do
      let(:activity) { create(:fund_activity) }

      it { is_expected.to forbid_action(:show) }
      it { is_expected.to forbid_action(:create) }
      it { is_expected.to forbid_action(:edit) }
      it { is_expected.to forbid_action(:update) }
      it { is_expected.to forbid_action(:destroy) }
      it { is_expected.to forbid_action(:redact_from_iati) }
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
      end
    end

    context "when the activity is a project" do
      let(:activity) { create(:project_activity) }

      context "and the activity does not belong to the same organisation as the user" do
        it { is_expected.to forbid_action(:show) }
        it { is_expected.to forbid_action(:create) }
        it { is_expected.to forbid_action(:edit) }
        it { is_expected.to forbid_action(:update) }
        it { is_expected.to forbid_action(:destroy) }
        it { is_expected.to forbid_action(:redact_from_iati) }
      end

      context "and the activity belongs to the same organisation as the user" do
        before do
          activity.update(organisation: user.organisation)
        end

        context "when there is no editable report for the users organisation" do
          it { is_expected.to permit_action(:show) }

          it { is_expected.to forbid_action(:create) }
          it { is_expected.to forbid_action(:edit) }
          it { is_expected.to forbid_action(:update) }
          it { is_expected.to forbid_action(:destroy) }
          it { is_expected.to forbid_action(:redact_from_iati) }
        end

        context "when there is an editable report for the users organisation" do
          before do
            report.update(state: :active)
          end

          context "and the associated fund is not the same as the activity" do
            it { is_expected.to permit_action(:show) }

            it { is_expected.to forbid_action(:edit) }
            it { is_expected.to forbid_action(:update) }
            it { is_expected.to forbid_action(:destroy) }
            it { is_expected.to forbid_action(:redact_from_iati) }
          end

          context "and the associated fund is the same as the activity" do
            before do
              report.update(fund: activity.associated_fund)
            end

            it { is_expected.to permit_action(:show) }
            it { is_expected.to permit_action(:create) }
            it { is_expected.to permit_action(:edit) }
            it { is_expected.to permit_action(:update) }

            it { is_expected.to forbid_action(:destroy) }
            it { is_expected.to forbid_action(:redact_from_iati) }
          end
        end
      end
    end

    context "when the activity is a third-party project" do
      let(:activity) { create(:third_party_project_activity) }

      it { is_expected.to forbid_action(:redact_from_iati) }
    end
  end
end
