require "rails_helper"

RSpec.describe MatchedEffortPolicy do
  subject { described_class.new(user, matched_effort) }

  let!(:report) { create(:report, :approved, organisation: user.organisation, fund: activity.associated_fund) }
  let(:matched_effort) { build_stubbed(:matched_effort, activity: activity) }

  context "as a user that belongs to BEIS" do
    let(:user) { build_stubbed(:beis_user) }

    context "when the activity is a programme activity owned by the organisation" do
      let(:activity) { build_stubbed(:programme_activity, organisation: user.organisation) }

      it { is_expected.to permit_action(:create) }
      it { is_expected.to permit_action(:update) }
      it { is_expected.to permit_action(:destroy) }
    end

    context "when the activity is a project activity" do
      let(:activity) { build_stubbed(:project_activity) }

      it { is_expected.to forbid_action(:create) }
      it { is_expected.to forbid_action(:update) }
      it { is_expected.to forbid_action(:destroy) }
    end
  end

  context "as a Delivery partner user" do
    let(:user) { build_stubbed(:delivery_partner_user) }

    context "when the matched effort belongs to an activity owned by the user" do
      let(:activity) { build_stubbed(:project_activity, organisation: user.organisation) }

      context "when there is an editable report for the organisation" do
        before do
          report.update(state: :active)
        end

        it { is_expected.to permit_action(:create) }
        it { is_expected.to permit_action(:update) }
        it { is_expected.to permit_action(:destroy) }
      end

      context "when there is ano editable report for the organisation" do
        it { is_expected.to forbid_action(:create) }
        it { is_expected.to forbid_action(:update) }
        it { is_expected.to forbid_action(:destroy) }
      end
    end

    context "when the matched effort does not belong to an activity owned by the user" do
      let(:activity) { build_stubbed(:project_activity) }

      context "when there is an editable report for the organisation" do
        before do
          report.update(state: :active)
        end

        it { is_expected.to forbid_action(:create) }
        it { is_expected.to forbid_action(:update) }
        it { is_expected.to forbid_action(:destroy) }
      end

      context "when there is ano editable report for the organisation" do
        it { is_expected.to forbid_action(:create) }
        it { is_expected.to forbid_action(:update) }
        it { is_expected.to forbid_action(:destroy) }
      end
    end
  end
end
