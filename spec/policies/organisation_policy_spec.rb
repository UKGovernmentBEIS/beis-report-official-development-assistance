require "rails_helper"

RSpec.describe OrganisationPolicy do
  subject { described_class.new(user, organisation) }

  let(:organisation) { create(:delivery_partner_organisation) }

  context "as user that belongs to BEIS" do
    let(:user) { build_stubbed(:beis_user) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_new_and_create_actions }
    it { is_expected.to permit_edit_and_update_actions }
    it { is_expected.to permit_action(:destroy) }
    it { is_expected.to permit_action(:download) }
  end

  context "as user that does NOT belong to BEIS" do
    context "when the user belongs to that organisation" do
      let(:user) { build_stubbed(:delivery_partner_user, organisation: organisation) }

      it { is_expected.to forbid_action(:index) }
      it { is_expected.to permit_action(:show) }
      it { is_expected.to forbid_new_and_create_actions }
      it { is_expected.to permit_edit_and_update_actions }
      it { is_expected.to forbid_action(:destroy) }
      it { is_expected.to forbid_action(:download) }
    end

    context "when the user does NOT belong to that organisation" do
      let(:user) { build_stubbed(:delivery_partner_user, organisation: create(:delivery_partner_organisation)) }

      it { is_expected.to forbid_action(:index) }
      it { is_expected.to forbid_action(:show) }
      it { is_expected.to forbid_new_and_create_actions }
      it { is_expected.to forbid_edit_and_update_actions }
      it { is_expected.to forbid_action(:destroy) }
      it { is_expected.to forbid_action(:download) }
    end
  end
end
