require "rails_helper"

RSpec.describe ActivityPolicy do
  subject { described_class.new(user, activity) }

  let(:organisation) { create(:organisation) }
  let(:fund) { create(:fund, organisation: organisation) }
  let(:activity) { create(:activity, hierarchy: fund) }

  context "as an administrator" do
    let(:user) { build_stubbed(:administrator) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_new_and_create_actions }
    it { is_expected.to permit_edit_and_update_actions }
    it { is_expected.to permit_action(:destroy) }
  end

  context "as a delivery partner" do
    let(:user) { build_stubbed(:user) }
    let(:resolved_scope) do
      described_class::Scope.new(user, Activity.all).resolve
    end

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_new_and_create_actions }
    it { is_expected.to permit_edit_and_update_actions }
    it { is_expected.to permit_action(:destroy) }

    context "with activities from funds in my own organisation" do
      let(:user) { create(:administrator, organisations: [organisation]) }

      it "includes activity in resolved scope" do
        expect(resolved_scope).to include(activity)
      end
    end

    context "with activities from funds in another organisation" do
      let(:other_organisation) { create(:organisation) }
      let(:forbidden_fund) { create(:fund, organisation: other_organisation) }
      let(:activity) { create(:activity, hierarchy: forbidden_fund) }

      it "does not include activity in resolved scope" do
        expect(resolved_scope).to_not include(activity)
      end
    end
  end
end
