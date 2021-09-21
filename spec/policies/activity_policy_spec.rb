require "rails_helper"

RSpec.describe ActivityPolicy do
  let!(:report) { create(:report, organisation: user.organisation, fund: activity.associated_fund, state: :approved) }
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
        is_expected.to forbid_action(:redact_from_iati)
        is_expected.to forbid_action(:create_refund)
        is_expected.to forbid_action(:create_adjustment)

        is_expected.to forbid_action(:create_child)
        is_expected.to permit_action(:create_transfer)
      end

      context "and there is an active report" do
        let(:activity) { create(:programme_activity, :with_report, organisation: user.organisation) }

        it { is_expected.to permit_action(:create_refund) }
        it { is_expected.to forbid_action(:create_adjustment) }
      end
    end

    context "when the activity is a project" do
      let(:activity) { create(:project_activity) }

      it "controls actions as expected" do
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
      end
    end

    context "when the activity is a third-party project" do
      let(:activity) { create(:third_party_project_activity) }

      it "controls actions as expected" do
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
      end
    end
  end

  context "as a Delivery partner user" do
    let(:user) { create(:delivery_partner_user) }

    context "when the activity is a fund" do
      let(:activity) { create(:fund_activity) }

      it "controls actions as expected" do
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
      end
    end

    context "when the activity is a programme" do
      let(:activity) { create(:programme_activity) }

      context "and the users organisation is not the extending organisation" do
        it "controls actions as expected" do
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
        end
      end

      context "and the users organisation is the extending organisation" do
        before do
          activity.update(extending_organisation: user.organisation)
        end

        it "controls actions as expected" do
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
        end

        context "and there is an editable report for the users organisation" do
          before do
            report.update(state: :active)
          end

          it "controls actions as expected" do
            is_expected.to permit_action(:create_child)
            is_expected.to forbid_action(:create_transfer)
            is_expected.to forbid_action(:create_refund)
            is_expected.to forbid_action(:create_adjustment)
          end
        end
      end
    end

    context "when the activity is a project" do
      let(:activity) { create(:project_activity) }

      context "and the users organisation is not the extending organisation" do
        it "controls actions as expected" do
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
        end
      end

      context "and the users organisation is the extending organisation" do
        before do
          activity.update(organisation: user.organisation, extending_organisation: user.organisation)
        end

        context "and there is no editable report for the users organisation" do
          before do
            report.update(state: :approved)
          end

          it "controls actions as expected" do
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
          end
        end

        context "and there is an editable report for the users organisation" do
          before do
            report.update(state: :active)
          end

          it "controls actions as expected" do
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
          end
        end
      end
    end

    context "when the activity is a third-party project" do
      let(:activity) { create(:third_party_project_activity) }

      context "and the users organisation is not the extending organisation" do
        it "controls actions as expected" do
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
        end
      end

      context "and the users organisation is the extending organisation" do
        before do
          activity.update(organisation: user.organisation, extending_organisation: user.organisation)
        end

        context "and there is no editable report for the users organisation" do
          it "controls actions as expected" do
            is_expected.to permit_action(:show)

            is_expected.to forbid_action(:create)
            is_expected.to forbid_action(:edit)
            is_expected.to forbid_action(:update)
            is_expected.to forbid_action(:destroy)
            is_expected.to forbid_action(:redact_from_iati)

            is_expected.to forbid_action(:create_child)
            is_expected.to forbid_action(:create_transfer)
            is_expected.to forbid_action(:create_refund)
          end
        end

        context "and there is an editable report for the users organisation" do
          before do
            report.update(state: :active)
          end

          it "controls actions as expected" do
            is_expected.to permit_action(:show)
            is_expected.to permit_action(:create)
            is_expected.to permit_action(:edit)
            is_expected.to permit_action(:update)

            is_expected.to forbid_action(:destroy)
            is_expected.to forbid_action(:redact_from_iati)

            is_expected.to forbid_action(:create_child)
            is_expected.to permit_action(:create_transfer)
            is_expected.to permit_action(:create_refund)
          end
        end
      end
    end
  end
end
