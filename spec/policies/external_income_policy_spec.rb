require "rails_helper"

RSpec.describe ExternalIncomePolicy do
  subject { described_class.new(user, external_income) }

  let!(:report) { create(:report, :approved, organisation: user.organisation, fund: activity.associated_fund) }
  let(:external_income) { build_stubbed(:external_income, activity: activity) }

  context "as a user that belongs to BEIS" do
    let(:user) { build_stubbed(:beis_user) }

    context "when the activity is a programme activity owned by the organisation" do
      let(:activity) { build_stubbed(:programme_activity, organisation: user.organisation) }

      it "permits all actions" do
        is_expected.to permit_action(:create)
        is_expected.to permit_action(:update)
        is_expected.to permit_action(:destroy)
      end
    end

    context "when the activity is a project activity" do
      let(:activity) { build_stubbed(:project_activity) }

      it "forbids all actions" do
        is_expected.to forbid_action(:create)
        is_expected.to forbid_action(:update)
        is_expected.to forbid_action(:destroy)
      end
    end
  end

  context "as a Delivery partner user" do
    let(:user) { build_stubbed(:delivery_partner_user) }

    context "when the external income belongs to an activity owned by the user" do
      let(:activity) { build_stubbed(:project_activity, organisation: user.organisation) }

      context "when there is an editable report for the organisation" do
        before do
          report.update(state: :active)
        end

        it "permits all actions" do
          is_expected.to permit_action(:create)
          is_expected.to permit_action(:update)
          is_expected.to permit_action(:destroy)
        end
      end

      context "when there is no editable report for the organisation" do
        it "forbids all actions" do
          is_expected.to forbid_action(:create)
          is_expected.to forbid_action(:update)
          is_expected.to forbid_action(:destroy)
        end
      end
    end

    context "when the external income does not belong to an activity owned by the user" do
      let(:activity) { build_stubbed(:project_activity) }

      context "when there is an editable report for the organisation" do
        before do
          report.update(state: :active)
        end

        it "forbids all actions" do
          is_expected.to forbid_action(:create)
          is_expected.to forbid_action(:update)
          is_expected.to forbid_action(:destroy)
        end
      end

      context "when there is no editable report for the organisation" do
        it "forbids all actions" do
          is_expected.to forbid_action(:create)
          is_expected.to forbid_action(:update)
          is_expected.to forbid_action(:destroy)
        end
      end
    end
  end
end
