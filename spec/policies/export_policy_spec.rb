require "rails_helper"

RSpec.describe ExportPolicy do
  let(:user) { build_stubbed(:beis_user) }

  subject { described_class.new(user, :export) }

  context "as a BEIS user" do
    let(:user) { create(:beis_user) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show_external_income) }
  end

  context "as a Delivery partner user" do
    let(:user) { create(:delivery_partner_user) }

    it { is_expected.to_not permit_action(:index) }
    it { is_expected.to_not permit_action(:show_external_income) }
  end
end
