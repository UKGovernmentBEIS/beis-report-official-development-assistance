require "rails_helper"

RSpec.describe ActivityPolicy do
  subject { described_class.new(user, activity) }

  let(:organisation) { create(:organisation) }
  let(:activity) { create(:activity, organisation: organisation) }

  context "as an administrator" do
    let(:user) { build_stubbed(:administrator) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_new_and_create_actions }
    it { is_expected.to permit_edit_and_update_actions }
    it { is_expected.to permit_action(:destroy) }

    it "includes activity in resolved scope" do
      resolved_scope = described_class::Scope.new(user, Activity.all).resolve
      expect(resolved_scope).to include(activity)
    end
  end
end
