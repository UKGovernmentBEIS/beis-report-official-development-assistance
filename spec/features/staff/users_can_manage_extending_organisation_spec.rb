RSpec.feature "Users can manage the extending organisation" do
  context "when the user belongs to BEIS" do
    let(:user) { create(:beis_user) }
    before { authenticate!(user: user) }

    context "and the activity is a programme" do
      let(:fund) { create(:fund_activity) }
      let(:programme) { create(:programme_activity, activity_id: fund.id, extending_organisation: nil) }

      scenario "they can set the extending organisation" do
        delivery_partner = create(:delivery_partner_organisation)
        visit organisation_activity_path(programme.organisation, programme)
        click_on I18n.t("tabs.activity.details")
        click_on I18n.t("page_content.activity.extending_organisation.button.edit")
        choose delivery_partner.name
        click_on I18n.t("default.button.submit")

        expect(page).to have_content("success")
        expect(page).to have_content delivery_partner.name
      end

      scenario "when the extending organisation is set, the same organisation is set as the implementing organisation" do
        delivery_partner = create(:delivery_partner_organisation)
        visit organisation_activity_path(programme.organisation, programme)
        click_on I18n.t("tabs.activity.details")
        click_on I18n.t("page_content.activity.extending_organisation.button.edit")
        choose delivery_partner.name
        click_on I18n.t("default.button.submit")

        implementing_organisation = programme.reload.implementing_organisations.first
        expect(implementing_organisation.name).to eq(delivery_partner.name)
        expect(implementing_organisation.organisation_type).to eq(delivery_partner.organisation_type)
        expect(implementing_organisation.reference).to eq(delivery_partner.iati_reference)
      end

      scenario "they can change the extending organistion" do
        delivery_partner = create(:delivery_partner_organisation)
        programme.update(extending_organisation: delivery_partner)
        another_delivery_partner = create(:delivery_partner_organisation)

        visit organisation_activity_path(programme.organisation, programme)
        click_on I18n.t("tabs.activity.details")
        click_on I18n.t("page_content.activity.extending_organisation.button.edit")

        expect(page).to have_checked_field delivery_partner.name

        choose another_delivery_partner.name
        click_on I18n.t("default.button.submit")

        expect(page).to have_content("success")
        expect(page).to have_content another_delivery_partner.name
      end

      scenario "when the extending organisation is changed, the implementing organisation is changed" do
        delivery_partner = create(:delivery_partner_organisation)
        programme.update(extending_organisation: delivery_partner)
        another_delivery_partner = create(:delivery_partner_organisation)

        visit organisation_activity_path(programme.organisation, programme)
        click_on I18n.t("tabs.activity.details")
        click_on I18n.t("page_content.activity.extending_organisation.button.edit")

        expect(page).to have_checked_field delivery_partner.name

        choose another_delivery_partner.name
        click_on I18n.t("default.button.submit")

        implementing_organisation = programme.reload.implementing_organisations.first
        expect(implementing_organisation.name).to eq(another_delivery_partner.name)
        expect(implementing_organisation.organisation_type).to eq(another_delivery_partner.organisation_type)
        expect(implementing_organisation.reference).to eq(another_delivery_partner.iati_reference)
      end

      scenario "not selecting an extending organisation results in an error" do
        visit organisation_activity_path(programme.organisation, programme)
        click_on I18n.t("tabs.activity.details")
        click_on I18n.t("page_content.activity.extending_organisation.button.edit")
        click_on I18n.t("default.button.submit")

        expect(page).to have_content "Error: Extending organisation can't be blank"
      end
    end
  end

  context "when the user does NOT belong to BEIS" do
    let(:user) { create(:delivery_partner_user) }
    before { authenticate!(user: user) }

    scenario "they cannot set the extending organisation" do
      fund = create(:fund_activity)
      programme = create(:programme_activity, activity_id: fund.id)

      visit organisation_activity_path(programme.organisation, programme)

      expect(page).not_to have_content(I18n.t("page_content.activity.extending_organisation.button.edit"))
    end
  end
end
