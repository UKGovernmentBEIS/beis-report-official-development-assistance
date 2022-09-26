RSpec.feature "BEIS users can create organisations" do
  context "when the user is not logged in" do
    before do
      logout
    end

    it "redirects the user to the root path" do
      visit new_organisation_path
      expect(current_path).to eq(root_path)
    end
  end

  context "when the user is authenticated" do
    let(:user) { create(:beis_user) }
    before do
      authenticate!(user: user)
      visit organisation_path(user.organisation)

      within ".govuk-header__navigation" do
        click_link t("page_title.organisation.index")
      end
    end

    def then_breadcrumb_shows_type_of_organisation(name:, link: nil)
      within ".govuk-breadcrumbs" do
        if link
          expect(page).to have_link(name, href: link)
        else
          expect(page).to have_content(name)
        end
      end
    end

    scenario "successfully creating a partner organisation" do
      click_link t("page_content.organisations.partner_organisations.button.create")

      then_breadcrumb_shows_type_of_organisation(
        name: "Partner organisations",
        link: organisations_path(role: "partner_organisations")
      )

      expect(page).to have_content(t("page_title.organisation.partner_organisation.new"))
      fill_in "organisation[name]", with: "My New Organisation"
      fill_in "organisation[beis_organisation_reference]", with: "MNO"
      fill_in "organisation[iati_reference]", with: "CZH-GOV-1234"
      select "Government", from: "organisation[organisation_type]"
      select "Czech", from: "organisation[language_code]"
      select "Zloty", from: "organisation[default_currency]"
      click_button t("default.button.submit")

      expect(page).to have_content(t("action.organisation.create.success"))
      expect(page).to_not have_field("organisation[active]", type: "radio")

      organisation = Organisation.order("created_at ASC").last

      expect(organisation.name).to eq("My New Organisation")
      expect(organisation.beis_organisation_reference).to eq("MNO")
      expect(organisation.iati_reference).to eq("CZH-GOV-1234")
      expect(organisation.organisation_type).to eq("10")
      expect(organisation.language_code).to eq("cs")
      expect(organisation.default_currency).to eq("PLN")
      expect(organisation.role).to eq("partner_organisation")
      expect(organisation.active).to eq(true)
    end

    scenario "successfully creating a matched effort provider organisation" do
      click_link t("tabs.organisations.matched_effort_providers")

      click_link t("page_content.organisations.matched_effort_providers.button.create")

      then_breadcrumb_shows_type_of_organisation(
        name: "Matched effort providers",
        link: organisations_path(role: "matched_effort_providers")
      )

      expect(page).to have_content(t("page_title.organisation.matched_effort_provider.new"))
      expect(page).to have_field("organisation[active]", type: "radio")

      fill_in "organisation[name]", with: "My New Organisation"
      select "Government", from: "organisation[organisation_type]"
      select "Czech", from: "organisation[language_code]"
      select "Zloty", from: "organisation[default_currency]"
      choose t("form.label.organisation.active.true"), name: "organisation[active]"

      click_button t("default.button.submit")

      organisation = Organisation.order("created_at ASC").last

      expect(page).to have_content(t("action.organisation.create.success"))

      expect(organisation.name).to eq("My New Organisation")
      expect(organisation.organisation_type).to eq("10")
      expect(organisation.language_code).to eq("cs")
      expect(organisation.default_currency).to eq("PLN")
      expect(organisation.role).to eq("matched_effort_provider")
      expect(organisation.active).to eq(true)
    end

    scenario "successfully creating a external income provider organisation" do
      click_link t("tabs.organisations.external_income_providers")

      click_link t("page_content.organisations.external_income_providers.button.create")
      then_breadcrumb_shows_type_of_organisation(
        name: "External income provider",
        link: organisations_path(role: "external_income_providers")
      )

      expect(page).to have_content(t("page_title.organisation.external_income_provider.new"))
      expect(page).to have_field("organisation[active]", type: "radio")

      fill_in "organisation[name]", with: "My New External Income Provider"
      select "Other", from: "organisation[organisation_type]"
      select "Russian", from: "organisation[language_code]"
      select "Russian Ruble", from: "organisation[default_currency]"
      choose t("form.label.organisation.active.true"), name: "organisation[active]"

      click_button t("default.button.submit")

      organisation = Organisation.order("created_at ASC").last

      expect(page).to have_content(t("action.organisation.create.success"))

      expect(organisation.name).to eq("My New External Income Provider")
      expect(organisation.organisation_type).to eq("90")
      expect(organisation.language_code).to eq("ru")
      expect(organisation.default_currency).to eq("RUB")
      expect(organisation.role).to eq("external_income_provider")
      expect(organisation.active).to eq(true)
    end

    scenario "successfully creating an implementing organisation" do
      def given_i_am_on_the_new_implementing_organisation_page
        click_link t("tabs.organisations.implementing_organisations")
        click_link t("page_content.organisations.implementing_organisations.button.create")
        expect(page).to have_content(t("page_title.organisation.implementing_organisation.new"))
        then_breadcrumb_shows_type_of_organisation(
          name: "Implementing organisations",
          link: organisations_path(role: "implementing_organisations")
        )
      end

      def and_i_submit_the_new_implementing_organisation_form
        click_button t("default.button.submit")
      end

      def then_i_expect_to_see_that_an_implementing_organisation_has_mandatory_fields
        within ".govuk-error-summary" do
          expect(page).to have_content("Enter an organisation type")
          expect(page).to have_content("Enter a language code")
          expect(page).to have_content("Enter a default currency")
          expect(page).to have_content("Enter an organisation name")
        end
      end

      def when_i_fill_in_the_implementing_organisation_form_correctly
        fill_in "organisation[name]", with: "A New Implementing Organisation"
        fill_in "organisation[beis_organisation_reference]", with: "ANIO"
        fill_in "organisation[iati_reference]", with: "CZH-GOV-1234"
        select "Other", from: "organisation[organisation_type]"
        select "English", from: "organisation[language_code]"
        select "Pound Sterling", from: "organisation[default_currency]"
      end

      def then_i_expect_to_see_the_created_implementing_organisation(organisation)
        presented_org = OrganisationPresenter.new(organisation)

        expect(page).to have_content(t("action.organisation.create.success"))
        expect(page).to have_content(presented_org.name)
        expect(page).to have_content(presented_org.iati_reference)
        expect(page).to have_content(presented_org.language_code)
        expect(page).to have_content(presented_org.default_currency)
        expect(page).to have_content(presented_org.organisation_type)
      end

      given_i_am_on_the_new_implementing_organisation_page
      and_i_submit_the_new_implementing_organisation_form
      then_i_expect_to_see_that_an_implementing_organisation_has_mandatory_fields

      when_i_fill_in_the_implementing_organisation_form_correctly
      and_i_submit_the_new_implementing_organisation_form
      then_i_expect_to_see_the_created_implementing_organisation(
        Organisation.order("created_at ASC").last
      )
    end

    scenario "presence validation works as expected" do
      click_link t("page_content.organisations.partner_organisations.button.create")

      expect(page).to have_content(t("page_title.organisation.partner_organisation.new"))
      fill_in "organisation[name]", with: "My New Organisation"

      click_button t("default.button.submit")
      expect(page).to_not have_content t("action.organisation.create.success")
      expect(page).to have_content t("activerecord.errors.models.organisation.attributes.organisation_type.blank")
    end
  end

  context "when the user does not belongs to BEIS" do
    let(:user) { create(:partner_organisation_user) }

    it "does not show them the manage user button" do
      visit organisation_path(user.organisation)
      expect(page).not_to have_link(t("page_title.organisation.index"))
    end
  end
end
