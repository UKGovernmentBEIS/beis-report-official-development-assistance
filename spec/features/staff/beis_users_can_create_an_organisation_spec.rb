RSpec.feature "BEIS users can create organisations" do
  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      visit new_organisation_path
      expect(current_path).to eq(root_path)
    end
  end

  context "when the user is authenticated" do
    let(:user) { create(:beis_user) }
    before do
      authenticate!(user: user)
    end

    scenario "successfully creating a delivery partner organisation" do
      visit organisation_path(user.organisation)
      click_link t("page_title.organisation.index")
      click_link t("page_content.organisations.delivery_partners.button.create")

      expect(page).to have_content(t("page_title.organisation.delivery_partner.new"))
      fill_in "organisation[name]", with: "My New Organisation"
      fill_in "organisation[beis_organisation_reference]", with: "MNO"
      fill_in "organisation[iati_reference]", with: "CZH-GOV-1234"
      select "Government", from: "organisation[organisation_type]"
      select "Czech", from: "organisation[language_code]"
      select "Zloty", from: "organisation[default_currency]"
      click_button t("default.button.submit")

      organisation = Organisation.order("created_at ASC").last

      expect(organisation.name).to eq("My New Organisation")
      expect(organisation.beis_organisation_reference).to eq("MNO")
      expect(organisation.iati_reference).to eq("CZH-GOV-1234")
      expect(organisation.organisation_type).to eq("10")
      expect(organisation.language_code).to eq("cs")
      expect(organisation.default_currency).to eq("PLN")
      expect(organisation.role).to eq("delivery_partner")
    end

    scenario "successfully creating a matched effort provider organisation" do
      visit organisation_path(user.organisation)
      click_link t("page_title.organisation.index")
      click_link t("tabs.organisations.matched_effort_providers")

      click_link t("page_content.organisations.matched_effort_providers.button.create")

      expect(page).to have_content(t("page_title.organisation.matched_effort_provider.new"))
      fill_in "organisation[name]", with: "My New Organisation"
      fill_in "organisation[beis_organisation_reference]", with: "MNO"
      fill_in "organisation[iati_reference]", with: "CZH-GOV-1234"
      select "Government", from: "organisation[organisation_type]"
      select "Czech", from: "organisation[language_code]"
      select "Zloty", from: "organisation[default_currency]"
      click_button t("default.button.submit")

      organisation = Organisation.order("created_at ASC").last

      expect(organisation.name).to eq("My New Organisation")
      expect(organisation.beis_organisation_reference).to eq("MNO")
      expect(organisation.iati_reference).to eq("CZH-GOV-1234")
      expect(organisation.organisation_type).to eq("10")
      expect(organisation.language_code).to eq("cs")
      expect(organisation.default_currency).to eq("PLN")
      expect(organisation.role).to eq("matched_effort_provider")
    end

    scenario "organisation creation is tracked with public_activity" do
      PublicActivity.with_tracking do
        visit organisation_path(user.organisation)
        click_link t("page_title.organisation.index")
        click_link t("page_content.organisations.delivery_partners.button.create")

        expect(page).to have_content(t("page_title.organisation.delivery_partner.new"))
        fill_in "organisation[name]", with: "My New Organisation"
        fill_in "organisation[beis_organisation_reference]", with: "mno"
        fill_in "organisation[iati_reference]", with: "CZH-GOV-1234"
        select "Government", from: "organisation[organisation_type]"
        select "Swedish", from: "organisation[language_code]"
        select "US Dollar", from: "organisation[default_currency]"
        click_button t("default.button.submit")

        organisation = Organisation.find_by(name: "My New Organisation")
        auditable_event = PublicActivity::Activity.find_by(trackable_id: organisation.id)
        expect(auditable_event.key).to eq "organisation.create"
        expect(auditable_event.owner_id).to eq user.id
        expect(auditable_event.trackable_id).to eq organisation.id
      end
    end

    scenario "presence validation works as expected" do
      visit organisation_path(user.organisation)
      click_link t("page_title.organisation.index")
      click_link t("page_content.organisations.delivery_partners.button.create")

      expect(page).to have_content(t("page_title.organisation.delivery_partner.new"))
      fill_in "organisation[name]", with: "My New Organisation"

      click_button t("default.button.submit")
      expect(page).to_not have_content t("action.organisation.create.success")
      expect(page).to have_content t("activerecord.errors.models.organisation.attributes.organisation_type.blank")
    end

    context "when the user does not belongs to BEIS" do
      let(:user) { create(:delivery_partner_user) }

      it "does not show them the manage user button" do
        visit organisation_path(user.organisation)
        expect(page).not_to have_content(t("page_title.organisation.index"))
      end
    end
  end
end
