require "rails_helper"

RSpec.describe Export::OrganisationPolicy do
  let(:organisation) { create(:delivery_partner_organisation) }

  subject { described_class.new(user, organisation) }

  context "for a BEIS user" do
    let(:user) { create(:beis_user) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:show_external_income) }
    it { is_expected.to permit_action(:show_transactions) }
    it { is_expected.to permit_action(:show_xml) }
  end

  context "for a delivery partner" do
    let(:user) { create(:delivery_partner_user) }

    it { is_expected.to forbid_action(:index) }
    it { is_expected.to forbid_action(:show) }
    it { is_expected.to forbid_action(:show_external_income) }
    it { is_expected.to forbid_action(:show_transactions) }
    it { is_expected.to forbid_action(:show_xml) }

    context "when the user's organisation matches the organisation" do
      let(:organisation) { user.organisation }

      it { is_expected.to permit_action(:show) }
      it { is_expected.to permit_action(:show_external_income) }

      it { is_expected.to forbid_action(:index) }
      it { is_expected.to forbid_action(:show_transactions) }
      it { is_expected.to forbid_action(:show_xml) }
    end
  end
end
