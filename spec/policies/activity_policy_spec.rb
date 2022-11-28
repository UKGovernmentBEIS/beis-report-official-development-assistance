require "rails_helper"

RSpec.describe ActivityPolicy do
  let!(:report) { create(:report, :approved, organisation: user.organisation, fund: activity.associated_fund) }
  let(:user) { build_stubbed(:beis_user) }

  subject { described_class.new(user, activity) }

  context "as a BEIS user" do
    let(:user) { create(:beis_user) }

    context "when the activity is a fund" do
      let(:activity) { create(:fund_activity, organisation: user.organisation, extending_organisation: user.organisation) }

      it "controls actions as expected" do
        is_expected.to permit_action(:show)
        is_expected.to permit_action(:create)
        is_expected.to permit_action(:edit)
        is_expected.to permit_action(:update)
        is_expected.to forbid_action(:destroy)
        is_expected.to forbid_action(:redact_from_iati)
        is_expected.to forbid_action(:create_refund)
        is_expected.to forbid_action(:create_adjustment)

        is_expected.to permit_action(:create_child)
        is_expected.to permit_action(:create_transfer)

        is_expected.to forbid_action(:update_linked_activity)
      end
    end

    context "when the activity is a programme" do
      let(:activity) { create(:programme_activity, organisation: user.organisation) }

      it "controls actions as expected" do
        is_expected.to permit_action(:show)
        is_expected.to permit_action(:create)
        is_expected.to permit_action(:edit)
        is_expected.to permit_action(:update)

        is_expected.to forbid_action(:destroy)
        is_expected.to permit_action(:redact_from_iati)
        is_expected.to forbid_action(:create_refund)
        is_expected.to forbid_action(:create_adjustment)

        is_expected.to forbid_action(:create_child)
        is_expected.to permit_action(:create_transfer)

        is_expected.to permit_action(:update_linked_activity)
      end

      context "and there is an active report" do
        let(:activity) { create(:programme_activity, :with_report, organisation: user.organisation) }

        it { is_expected.to permit_action(:create_refund) }
        it { is_expected.to forbid_action(:create_adjustment) }
      end

      context "when the activity has child activities that are linked to other activities" do
        let(:activity) { create(:programme_activity, :ispf_funded) }

        before { allow(activity).to receive(:linked_child_activities).and_return([double(:child_activity)]) }

        it { is_expected.to forbid_action(:update_linked_activity) }
      end
    end

    context "when the activity is a project" do
      let(:activity) { create(:project_activity) }

      it "only permits show and redact_from_iati" do
        is_expected.to permit_action(:show)
        is_expected.to permit_action(:redact_from_iati)

        is_expected.to forbid_action(:create_refund)
        is_expected.to forbid_action(:create_adjustment)

        is_expected.to forbid_action(:create)
        is_expected.to forbid_action(:edit)
        is_expected.to forbid_action(:update)
        is_expected.to forbid_action(:destroy)

        is_expected.to forbid_action(:create_child)
        is_expected.to forbid_action(:create_transfer)
        is_expected.to forbid_action(:update_linked_activity)
      end

      context "and there is an active report for the project's organisation" do
        let(:activity) { create(:project_activity, :with_report) }

        it "permits update_linked_activity" do
          is_expected.to permit_action(:update_linked_activity)
        end

        context "when the project has child activities that are linked to other activities" do
          before { allow(activity).to receive(:linked_child_activities).and_return([double(:child_activity)]) }

          it "forbids update_linked_activity" do
            is_expected.to forbid_action(:update_linked_activity)
          end
        end
      end
    end

    context "when the activity is a third-party project" do
      let(:activity) { create(:third_party_project_activity) }

      it "only permits show and redact_from_iati" do
        is_expected.to permit_action(:show)
        is_expected.to permit_action(:redact_from_iati)

        is_expected.to forbid_action(:create)
        is_expected.to forbid_action(:edit)
        is_expected.to forbid_action(:update)
        is_expected.to forbid_action(:destroy)

        is_expected.to forbid_action(:create_child)
        is_expected.to forbid_action(:create_transfer)
        is_expected.to forbid_action(:create_refund)
        is_expected.to forbid_action(:create_adjustment)
        is_expected.to forbid_action(:update_linked_activity)
      end

      context "and there is an active report for the project's organisation" do
        let(:activity) { create(:third_party_project_activity, :with_report) }

        it "permits update_linked_activity" do
          is_expected.to permit_action(:update_linked_activity)
        end
      end
    end
  end

  context "as a partner organisation user" do
    let(:user) { create(:partner_organisation_user) }

    context "when the activity is a fund" do
      let(:activity) { create(:fund_activity) }

      it "forbids all actions" do
        is_expected.to forbid_action(:show)
        is_expected.to forbid_action(:create)
        is_expected.to forbid_action(:edit)
        is_expected.to forbid_action(:update)
        is_expected.to forbid_action(:destroy)
        is_expected.to forbid_action(:redact_from_iati)

        is_expected.to forbid_action(:create_child)
        is_expected.to forbid_action(:create_transfer)
        is_expected.to forbid_action(:create_refund)
        is_expected.to forbid_action(:create_adjustment)
        is_expected.to forbid_action(:update_linked_activity)
      end
    end

    context "when the activity is a programme" do
      let(:activity) { create(:programme_activity) }

      context "and the user's organisation is not the extending organisation" do
        it "forbids all actions" do
          is_expected.to forbid_action(:show)
          is_expected.to forbid_action(:create)
          is_expected.to forbid_action(:edit)
          is_expected.to forbid_action(:update)
          is_expected.to forbid_action(:destroy)
          is_expected.to forbid_action(:redact_from_iati)

          is_expected.to forbid_action(:create_child)
          is_expected.to forbid_action(:create_transfer)
          is_expected.to forbid_action(:create_refund)
          is_expected.to forbid_action(:create_adjustment)
          is_expected.to forbid_action(:update_linked_activity)
        end
      end

      context "and the user's organisation is the extending organisation" do
        before do
          activity.update(extending_organisation: user.organisation)
        end

        it "only permits show" do
          is_expected.to permit_action(:show)

          is_expected.to forbid_action(:create)
          is_expected.to forbid_action(:edit)
          is_expected.to forbid_action(:update)
          is_expected.to forbid_action(:destroy)
          is_expected.to forbid_action(:redact_from_iati)

          is_expected.to forbid_action(:create_child)
          is_expected.to forbid_action(:create_transfer)
          is_expected.to forbid_action(:create_refund)
          is_expected.to forbid_action(:create_adjustment)
          is_expected.to forbid_action(:update_linked_activity)
        end

        context "and there is an editable report for the user's organisation" do
          before do
            report.update(state: :active)
          end

          it "only permits create_child" do
            is_expected.to permit_action(:create_child)
            is_expected.to forbid_action(:create_transfer)
            is_expected.to forbid_action(:create_refund)
            is_expected.to forbid_action(:create_adjustment)
            is_expected.to forbid_action(:update_linked_activity)
          end
        end
      end
    end

    context "when the activity is a project" do
      let(:activity) { create(:project_activity) }

      context "and the user's organisation is not the extending organisation" do
        it "forbids all actions" do
          is_expected.to forbid_action(:show)
          is_expected.to forbid_action(:create)
          is_expected.to forbid_action(:edit)
          is_expected.to forbid_action(:update)
          is_expected.to forbid_action(:destroy)
          is_expected.to forbid_action(:redact_from_iati)

          is_expected.to forbid_action(:create_child)
          is_expected.to forbid_action(:create_transfer)
          is_expected.to forbid_action(:create_refund)
          is_expected.to forbid_action(:create_adjustment)
          is_expected.to forbid_action(:update_linked_activity)
        end
      end

      context "and the user's organisation is the extending organisation" do
        before do
          activity.update(organisation: user.organisation, extending_organisation: user.organisation)
        end

        context "and there is no editable report for the user's organisation" do
          before do
            report.update(state: :approved)
          end

          it "only permits show" do
            is_expected.to permit_action(:show)

            is_expected.to forbid_action(:create)
            is_expected.to forbid_action(:edit)
            is_expected.to forbid_action(:update)
            is_expected.to forbid_action(:destroy)
            is_expected.to forbid_action(:redact_from_iati)

            is_expected.to forbid_action(:create_child)
            is_expected.to forbid_action(:create_transfer)
            is_expected.to forbid_action(:create_refund)
            is_expected.to forbid_action(:create_adjustment)
            is_expected.to forbid_action(:update_linked_activity)
          end
        end

        context "and there is an editable report for the user's organisation" do
          before do
            report.update(state: :active)
          end

          it "only forbids destroy and redact_from_iati" do
            is_expected.to permit_action(:show)
            is_expected.to permit_action(:create)
            is_expected.to permit_action(:edit)
            is_expected.to permit_action(:update)

            is_expected.to forbid_action(:destroy)
            is_expected.to forbid_action(:redact_from_iati)

            is_expected.to permit_action(:create_child)
            is_expected.to permit_action(:create_transfer)
            is_expected.to permit_action(:create_refund)
            is_expected.to permit_action(:create_adjustment)
            is_expected.to permit_action(:update_linked_activity)
          end

          context "when the activity has child activities that are linked to other activities" do
            before { allow(activity).to receive(:linked_child_activities).and_return([double(:child_activity)]) }

            it { is_expected.to forbid_action(:update_linked_activity) }
          end
        end
      end
    end

    context "when the activity is a third-party project" do
      let(:activity) { create(:third_party_project_activity) }

      context "and the user's organisation is not the extending organisation" do
        it "forbids all actions" do
          is_expected.to forbid_action(:show)
          is_expected.to forbid_action(:create)
          is_expected.to forbid_action(:edit)
          is_expected.to forbid_action(:update)
          is_expected.to forbid_action(:destroy)
          is_expected.to forbid_action(:redact_from_iati)

          is_expected.to forbid_action(:create_child)
          is_expected.to forbid_action(:create_transfer)
          is_expected.to forbid_action(:create_refund)
          is_expected.to forbid_action(:create_adjustment)
          is_expected.to forbid_action(:update_linked_activity)
        end
      end

      context "and the user's organisation is the extending organisation" do
        before do
          activity.update(organisation: user.organisation, extending_organisation: user.organisation)
        end

        context "and there is no editable report for the user's organisation" do
          it "only permits show" do
            is_expected.to permit_action(:show)

            is_expected.to forbid_action(:create)
            is_expected.to forbid_action(:edit)
            is_expected.to forbid_action(:update)
            is_expected.to forbid_action(:destroy)
            is_expected.to forbid_action(:redact_from_iati)

            is_expected.to forbid_action(:create_child)
            is_expected.to forbid_action(:create_transfer)
            is_expected.to forbid_action(:create_refund)
            is_expected.to forbid_action(:update_linked_activity)
          end
        end

        context "and there is an editable report for the user's organisation" do
          before do
            report.update(state: :active)
          end

          it "only forbids destroy, redact_from_iati, and create_child" do
            is_expected.to permit_action(:show)
            is_expected.to permit_action(:create)
            is_expected.to permit_action(:edit)
            is_expected.to permit_action(:update)

            is_expected.to forbid_action(:destroy)
            is_expected.to forbid_action(:redact_from_iati)

            is_expected.to forbid_action(:create_child)
            is_expected.to permit_action(:create_transfer)
            is_expected.to permit_action(:create_refund)
            is_expected.to permit_action(:update_linked_activity)
          end
        end
      end
    end
  end
end
