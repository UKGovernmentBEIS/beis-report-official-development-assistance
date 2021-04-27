require "rails_helper"

RSpec.describe CommentPolicy do
  let(:activity) { create(:fund_activity) }
  let(:report) { create(:report, :active, fund: activity, organisation: user.organisation) }
  let(:comment) { create(:comment, activity: activity, report: report, owner: user) }

  subject { described_class.new(user, comment) }

  context "when the owner is a BEIS user" do
    let(:user) { create(:beis_user) }

    describe "#show?" do
      it { is_expected.to permit_action(:show) }
    end

    describe "#create?" do
      it { is_expected.to forbid_action(:create) }
    end

    describe "#update?" do
      it { is_expected.to forbid_action(:update) }
    end

    describe "#destroy?" do
      it { is_expected.to forbid_action(:destroy) }
    end
  end

  context "when the owner is a Delivery Partner user" do
    let(:user) { create(:delivery_partner_user) }

    describe "#show" do
      context "when the attached report is viewable by the delivery partner" do
        it { is_expected.to permit_action(:show) }
      end

      context "when the attached report is not viewable by the delivery partner" do
        let(:comment) { create(:comment, activity: activity, report: create(:report), owner: user) }
        it { is_expected.to forbid_action(:show) }
      end
    end

    describe "#create?" do
      context "when there is an editable report to attach this comment to" do
        it { is_expected.to permit_action(:create) }
      end

      context "when there is not an editable report to attach this comment to" do
        let(:report) { create(:report, fund: activity, organisation: user.organisation) }
        it { is_expected.to forbid_action(:create) }
      end
    end

    describe "#update?" do
      context "when there is an editable report to attach this comment to" do
        it { is_expected.to permit_action(:update) }
      end

      context "when there is not an editable report to attach this comment to" do
        let(:report) { create(:report, fund: activity, organisation: user.organisation) }
        it { is_expected.to forbid_action(:update) }
      end

      context "when the comment was made by a user in the same Delivery Partner organisation" do
        let(:comment) { create(:comment, activity: activity, report: report, owner: create(:delivery_partner_user, organisation: user.organisation)) }
        it { is_expected.to permit_action(:update) }
      end
    end

    describe "#destroy?" do
      it { is_expected.to forbid_action(:destroy) }
    end
  end
end
