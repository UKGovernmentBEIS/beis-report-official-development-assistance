require "rails_helper"

RSpec.describe Export::OrganisationPolicy do
  subject { described_class.new(user, :export) }

  context "for a BEIS user" do
    let(:user) { create(:beis_user) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
  end

  context "for a delivery partner" do
    let(:user) { create(:delivery_partner_user) }

    it { is_expected.to forbid_action(:index) }
    it { is_expected.to forbid_action(:show) }
  end
end
