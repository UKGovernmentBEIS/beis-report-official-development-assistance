RSpec.feature "BEIS users can create a programme level activity" do
  let(:user) { create(:beis_user) }
  let(:delivery_partner) { create(:delivery_partner_organisation) }
  before { authenticate!(user: user) }

  context "with a new fund and delivery partner" do
    scenario "they see the button to add a new programme (level B activity)" do
      fund = create(:fund_activity, :gcrf)
      delivery_partner_organisation = create(:delivery_partner_organisation)

      visit organisation_activities_path(delivery_partner_organisation)

      expect(page).to have_button(t("form.button.activity.new_child", name: fund.title))
    end
  end

  context "via a delivery partner's activities page" do
    before do
      create(:fund_activity, :gcrf)
      create(:fund_activity, :newton)
    end

    Activity.fund.each do |fund|
      context "with #{fund.title} as the funding source" do
        scenario "reaches the 'roda_identifier' form step, with a newly created programme-level activity" do
          visit organisation_activities_path(delivery_partner)

          click_on t("form.button.activity.new_child", name: fund.title)

          expect(page).to have_content t("form.label.activity.delivery_partner_identifier")

          programme = Activity.programme.first

          expect(programme.form_state).to eq("identifier")
          expect(programme.parent).to eq(fund)
          expect(programme.source_fund).to eq(fund.source_fund)
        end
      end
    end
  end

  scenario "the activity can be created with the appropriate defaults" do
    fund = create(:fund_activity, :newton)
    identifier = "a-fund-has-an-accountable-organisation"

    visit organisation_activities_path(delivery_partner)
    click_on t("form.button.activity.new_child", name: fund.title)

    fill_in_activity_form(delivery_partner_identifier: identifier, level: "programme", parent: fund)

    activity = Activity.find_by(delivery_partner_identifier: identifier)

    expect(activity.accountable_organisation_name).to eq("Department for Business, Energy and Industrial Strategy")
    expect(activity.accountable_organisation_reference).to eq("GB-GOV-13")
    expect(activity.accountable_organisation_type).to eq("10")

    expect(activity.transparency_identifier).to eql("GB-GOV-13-#{activity.roda_identifier}")
  end

  scenario "a new programme requires specific fields when it is Newton-funded" do
    newton_fund = create(:fund_activity, :newton)

    visit organisation_activities_path(delivery_partner)
    click_on t("form.button.activity.new_child", name: newton_fund.title)

    fill_in_activity_form(level: "programme", parent: newton_fund)
  end
end
