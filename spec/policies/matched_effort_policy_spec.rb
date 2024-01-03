require "rails_helper"

RSpec.describe MatchedEffortPolicy do
  subject { described_class.new(user, matched_effort) }

  let!(:report) { create(:report, :approved, organisation: user.organisation, fund: activity.associated_fund) }
  let(:matched_effort) { create(:matched_effort, activity: activity) }

  context "as a user that belongs to BEIS" do
    let(:user) { create(:beis_user) }

    context "when the activity is a programme activity owned by the organisation" do
      let(:activity) { create(:programme_activity, organisation: user.organisation) }

      it "permits all actions" do
        is_expected.to permit_action(:create)
        is_expected.to permit_action(:update)
        is_expected.to permit_action(:destroy)
      end
    end

    context "when the activity is a project activity" do
      let(:activity) { create(:project_activity) }

      it "forbids all actions" do
        is_expected.to forbid_action(:create)
        is_expected.to forbid_action(:update)
        is_expected.to forbid_action(:destroy)
      end
    end
  end

  context "as a partner organisation user" do
    let(:user) { create(:partner_organisation_user) }

    context "when the matched effort belongs to an activity owned by the user" do
      let(:activity) { create(:project_activity, organisation: user.organisation) }

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

      context "when there is ano editable report for the organisation" do
        it "forbids all actions" do
          is_expected.to forbid_action(:create)
          is_expected.to forbid_action(:update)
          is_expected.to forbid_action(:destroy)
        end
      end
    end

    context "when the matched effort does not belong to an activity owned by the user" do
      let(:activity) { create(:project_activity) }

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
