require "rails_helper"

RSpec.describe Export::OrganisationPolicy do
  let(:organisation) { create(:partner_organisation) }

  subject { described_class.new(user, organisation) }

  context "for a BEIS user" do
    let(:user) { create(:beis_user) }

    it "controls access as expected" do
      is_expected.to permit_action(:index)
      is_expected.to permit_action(:show)
      is_expected.to permit_action(:show_external_income)
      is_expected.to permit_action(:show_transactions)
      is_expected.to permit_action(:show_xml)
      is_expected.to permit_action(:show_budgets)
      is_expected.to permit_action(:show_spending_breakdown)
    end
  end

  context "for a partner organisation user" do
    let(:user) { create(:delivery_partner_user) }

    it "controls access as expected" do
      is_expected.to forbid_action(:index)
      is_expected.to forbid_action(:show)
      is_expected.to forbid_action(:show_external_income)
      is_expected.to forbid_action(:show_transactions)
      is_expected.to forbid_action(:show_xml)
      is_expected.to forbid_action(:show_budgets)
      is_expected.to forbid_action(:show_spending_breakdown)
    end

    context "when the user's organisation matches the organisation" do
      let(:organisation) { user.organisation }

      it "controls access as expected" do
        is_expected.to permit_action(:show)
        is_expected.to permit_action(:show_external_income)
        is_expected.to permit_action(:show_budgets)
        is_expected.to forbid_action(:index)
        is_expected.to forbid_action(:show_transactions)
        is_expected.to forbid_action(:show_xml)
        is_expected.to permit_action(:show_spending_breakdown)
      end
    end
  end
end
