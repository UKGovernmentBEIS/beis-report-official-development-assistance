RSpec.feature "Users can choose a recipient country" do
  include CodelistHelper

  context "when the user is signed as a BEIS user" do
    let(:user) { create(:beis_user) }
    before { authenticate!(user: user) }
    let(:activity) { create(:activity, :at_geography_step, organisation: user.organisation) }

    before do
      visit activity_step_path(activity, :geography)
      choose "Country"
      click_button I18n.t("form.activity.submit")
    end

    context "with JavaScript disabled" do
      scenario "countries are choosen from a select box" do
        expect(page).to have_select(I18n.t("activerecord.attributes.activity.recipient_country"))
      end

      scenario "choosing a recipient country sets a recipient region associated to that country" do
        select "Botswana"
        click_button I18n.t("form.activity.submit")
        expect(activity.reload.recipient_region).to eq("289") # South of Sahara
      end
    end

    context "with JavaScript enabled", js: true do
      scenario "countries are choosen from an autocomplete" do
        expect(page).not_to have_select(I18n.t("activerecord.attributes.activity.recipient_country"))
        expect(page).to have_field(I18n.t("activerecord.attributes.activity.recipient_country"))
        expect(page).to have_css("input.autocomplete__input")
      end

      scenario "typing a partial match displays all the matching countries" do
        fill_in "Country", with: "saint"

        expect(page).to have_selector "li.autocomplete__option", text: "Saint Lucia", visible: true
        expect(page).to have_selector "li.autocomplete__option", text: "Saint Vincent and the Grenadines", visible: true

        expect(page).not_to have_selector "li.autocomplete__option", text: "United Kingdom of Great Britain and Northern Ireland (the)", visible: true
      end

      scenario "clicking the autocomplete shows all available countries" do
        find("#activity-recipient-country-field").click

        expect(page).to have_selector "li.autocomplete__option", count: country_select_options.count - 1, visible: true

        expect(page).to have_selector "li.autocomplete__option", text: "Afghanistan", visible: true
        expect(page).to have_selector "li.autocomplete__option", text: "Zimbabwe", visible: true
      end

      scenario "typing a known country displays that country in the list of countries" do
        fill_in "Country", with: "afghanistan"

        expect(page).to have_selector "li.autocomplete__option", text: "Afghanistan", visible: true
      end

      scenario "typing a complete country name, clicking it in the list and clicking continue saves the country" do
        fill_in "Country", with: "Saint Lucia"
        find("li.autocomplete__option", text: "Saint Lucia").click
        click_button I18n.t("form.activity.submit")
        click_on I18n.t("generic.link.back")

        within(".recipient_country") do
          expect(page).to have_content "Saint Lucia"
        end
      end

      scenario "typing a partial match, clicking on the complete match and clicking continue saves the country " do
        fill_in "Country", with: "saint"
        find("li.autocomplete__option", text: "Saint Lucia").click
        click_button I18n.t("form.activity.submit")
        click_on I18n.t("generic.link.back")

        within(".recipient_country") do
          expect(page).to have_content "Saint Lucia"
        end
      end

      scenario "choosing a recipient country sets a recipient region associated to that country" do
        fill_in "Country", with: "saint"
        find("li.autocomplete__option", text: "Saint Lucia").click
        click_button I18n.t("form.activity.submit")
        expect(activity.reload.recipient_region).to eq("380") # West Indies
      end
    end
  end
end
