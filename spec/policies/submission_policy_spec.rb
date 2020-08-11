require "rails_helper"

RSpec.describe SubmissionPolicy do
  let(:organisation) { create(:delivery_partner_organisation) }
  let(:submission) { create(:submission, organisation: organisation) }
  let(:another_submission) { create(:submission, organisation: create(:organisation)) }

  subject { described_class.new(user, submission) }

  context "as a user that belongs to BEIS" do
    let(:user) { build_stubbed(:beis_user) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_new_and_create_actions }
    it { is_expected.to permit_edit_and_update_actions }
    it { is_expected.to forbid_action(:destroy) }
    it { is_expected.to permit_action(:download) }

    it "includes all submissions in the resolved scope" do
      resolved_scope = described_class::Scope.new(user, Submission).resolve
      expect(resolved_scope).to include submission, another_submission
    end
  end

  context "as a user that does NOT belong to BEIS" do
    let(:user) { build_stubbed(:delivery_partner_user, organisation: organisation) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to forbid_new_and_create_actions }
    it { is_expected.to forbid_new_and_create_actions }
    it { is_expected.to forbid_action(:destroy) }

    context "when the submission belongs to the user's organisation" do
      let(:submission) { create(:submission, organisation: user.organisation) }
      it { is_expected.to permit_action(:download) }
      it { is_expected.to permit_action(:show) }
    end

    context "when the submission does not belong to the user's organisation" do
      let(:submission) { create(:submission, organisation: create(:organisation)) }
      it { is_expected.to forbid_action(:download) }
      it { is_expected.to forbid_action(:show) }
    end

    it "includes only submissions that the users organisation is reporting in the resolved scope" do
      resolved_scope = described_class::Scope.new(user, Submission).resolve
      expect(resolved_scope).to contain_exactly submission
    end
  end
end
