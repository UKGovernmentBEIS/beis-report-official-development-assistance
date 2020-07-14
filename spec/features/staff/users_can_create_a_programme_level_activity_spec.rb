RSpec.feature "Users can create a programme activity" do
  let(:user) { create(:beis_user) }

  context "when signed in as a BEIS user" do
    before do
      authenticate!(user: user)
    end

    scenario "successfully creates a programme" do
      fund = create(:fund_activity, organisation: user.organisation)

      visit activities_path
      click_on(I18n.t("page_content.organisation.button.create_activity"))

      fill_in_activity_form(level: "programme", parent: fund)

      expect(page).to have_content I18n.t("action.programme.create.success")
    end

    scenario "the activity has the appropriate funding organisation defaults" do
      fund = create(:activity, level: :fund, organisation: user.organisation)
      identifier = "a-programme-has-a-funding-organisation"

      visit activities_path
      click_on fund.title
      click_on I18n.t("tabs.activity.details")
      click_on(I18n.t("page_content.organisation.button.create_activity"))

      fill_in_activity_form(identifier: identifier, level: "programme", parent: fund)

      activity = Activity.find_by(identifier: identifier)
      expect(activity.funding_organisation_name).to eq("Department for Business, Energy and Industrial Strategy")
      expect(activity.funding_organisation_reference).to eq("GB-GOV-13")
      expect(activity.funding_organisation_type).to eq("10")
    end

    scenario "the activity has the appropriate accountable organisation defaults" do
      fund = create(:activity, level: :fund, organisation: user.organisation)
      identifier = "a-fund-has-an-accountable-organisation"

      visit activities_path
      click_on fund.title
      click_on I18n.t("tabs.activity.details")
      click_on(I18n.t("page_content.organisation.button.create_activity"))

      fill_in_activity_form(identifier: identifier, level: "programme", parent: fund)

      activity = Activity.find_by(identifier: identifier)
      expect(activity.accountable_organisation_name).to eq("Department for Business, Energy and Industrial Strategy")
      expect(activity.accountable_organisation_reference).to eq("GB-GOV-13")
      expect(activity.accountable_organisation_type).to eq("10")
    end

    scenario "programme creation is tracked with public_activity" do
      fund = create(:activity, level: :fund, organisation: user.organisation)

      PublicActivity.with_tracking do
        visit activities_path
        click_on fund.title
        click_on I18n.t("tabs.activity.details")
        click_on(I18n.t("page_content.organisation.button.create_activity"))

        fill_in_activity_form(identifier: "my-unique-identifier", level: "programme", parent: fund)

        programme = Activity.find_by(identifier: "my-unique-identifier")
        auditable_events = PublicActivity::Activity.where(trackable_id: programme.id)
        expect(auditable_events.map { |event| event.key }).to include("activity.create", "activity.create.identifier", "activity.create.purpose", "activity.create.sector", "activity.create.geography", "activity.create.region", "activity.create.flow", "activity.create.aid_type")
        expect(auditable_events.map { |event| event.owner_id }.uniq).to eq [user.id]
        expect(auditable_events.map { |event| event.trackable_id }.uniq).to eq [programme.id]
      end
    end
  end
end
