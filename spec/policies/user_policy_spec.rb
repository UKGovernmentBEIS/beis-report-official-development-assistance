require "rails_helper"

RSpec.describe UserPolicy do
  subject { described_class.new(user, target_user) }

  let(:target_user) { create(:delivery_partner) }

  context "as an administrator" do
    let(:user) { build_stubbed(:administrator) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_new_and_create_actions }
    it { is_expected.to permit_edit_and_update_actions }
    it { is_expected.to permit_action(:destroy) }
  end

  context "as a fund manager" do
    let(:user) { build_stubbed(:fund_manager) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_new_and_create_actions }
    it { is_expected.to permit_edit_and_update_actions }
    it { is_expected.to permit_action(:destroy) }
  end

  context "as a delivery partner" do
    let(:user) { build_stubbed(:delivery_partner) }

    it { is_expected.to forbid_action(:index) }
    it { is_expected.to forbid_action(:show) }
    it { is_expected.to forbid_new_and_create_actions }
    it { is_expected.to forbid_edit_and_update_actions }
    it { is_expected.to forbid_action(:destroy) }
  end
end
