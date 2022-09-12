require "rails_helper"

RSpec.describe ExportPolicy do
  let(:user) { build_stubbed(:beis_user) }

  subject { described_class.new(user, :export) }

  context "as a BEIS user" do
    let(:user) { create(:beis_user) }

    it "controls actions as expected" do
      is_expected.to permit_action(:index)
      is_expected.to permit_action(:show_external_income)
      is_expected.to permit_action(:show_budgets)
      is_expected.to permit_action(:show_spending_breakdown)
    end
  end

  context "as a partner organisation user" do
    let(:user) { create(:partner_organisation_user) }

    it "controls actions as expected" do
      is_expected.to forbid_action(:index)
      is_expected.to forbid_action(:show_external_income)
      is_expected.to forbid_action(:show_budgets)
      is_expected.to forbid_action(:show_spending_breakdown)
    end
  end
end
