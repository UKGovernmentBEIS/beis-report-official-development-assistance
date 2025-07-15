RSpec.feature "Users can switch organisation" do
  context "when the user has additional organisations" do
    let(:user_with_additional_organisations) do
      org1 = create(:partner_organisation)
      org2 = create(:partner_organisation)
      user = create(:partner_organisation_user)
      user.additional_organisations << [org1, org2]
      user
    end

    before do
      authenticate!(user: user_with_additional_organisations)
      visit root_path
    end
    after { logout }

    scenario "the organisation switcher dropdown is shown" do
      expect(page).to have_content t("organisation_switcher.label")
    end

    scenario "the organisation switcher dropdown is populated correctly" do
      user_with_additional_organisations.all_organisations.each do |org|
        expect(page).to have_content org.name
      end
    end

    scenario "the user can switch organisation" do
      expect(page).to have_select("current_user_organisation", selected: user_with_additional_organisations.primary_organisation.name)

      additional_org_name = user_with_additional_organisations.additional_organisations.first.name

      select(additional_org_name, from: "current_user_organisation")
      click_on t("organisation_switcher.submit")

      expect(page).to have_select("current_user_organisation", selected: additional_org_name)
    end

    scenario "the nav links have the correct organisation ID when the user has switched organisation" do
      additional_org = user_with_additional_organisations.additional_organisations.first

      activities_href = organisation_activities_path(organisation_id: user_with_additional_organisations.primary_organisation.id)
      exports_href = exports_organisation_path(id: user_with_additional_organisations.primary_organisation.id)

      expect(page).to have_link(href: activities_href)
      expect(page).to have_link(href: exports_href)

      select(additional_org.name, from: "current_user_organisation")
      click_on t("organisation_switcher.submit")

      updated_activities_href = organisation_activities_path(organisation_id: additional_org.id)
      updated_exports_href = exports_organisation_path(id: additional_org.id)

      expect(page).to have_link(href: updated_activities_href)
      expect(page).to have_link(href: updated_exports_href)
    end

    scenario "the Activities page shows the correct content when the user has switched organisation" do
      additional_org = user_with_additional_organisations.additional_organisations.first

      select(additional_org.name, from: "current_user_organisation")
      click_on t("organisation_switcher.submit")

      updated_activities_href = organisation_activities_path(organisation_id: additional_org.id)

      visit(updated_activities_href)

      expect(page).to have_content(t("page_title.activity.index"))
    end

    scenario "the Exports page shows the correct content when the user has switched organisation" do
      additional_org = user_with_additional_organisations.additional_organisations.first

      select(additional_org.name, from: "current_user_organisation")
      click_on t("organisation_switcher.submit")

      updated_exports_href = exports_organisation_path(id: additional_org.id)

      visit(updated_exports_href)

      expect(page).to have_content(t("page_title.export.organisation.show", name: additional_org.name))
    end

    scenario "the nav links have the primary organisation ID when the user has switched organisation and switched back" do
      activities_href = organisation_activities_path(organisation_id: user_with_additional_organisations.primary_organisation.id)
      exports_href = exports_organisation_path(id: user_with_additional_organisations.primary_organisation.id)

      additional_org = user_with_additional_organisations.additional_organisations.first

      select(additional_org.name, from: "current_user_organisation")
      click_on t("organisation_switcher.submit")

      updated_exports_href = exports_organisation_path(id: additional_org.id)

      visit(updated_exports_href)

      select(user_with_additional_organisations.primary_organisation.name, from: "current_user_organisation")
      click_on t("organisation_switcher.submit")

      expect(page).to have_link(href: activities_href)
      expect(page).to have_link(href: exports_href)
    end
  end

  context "when a BEIS user has switched organisation" do
    let(:user_with_additional_organisations) do
      user = create(:beis_user)
      user.additional_organisations << [
        create(:partner_organisation),
        create(:partner_organisation),
        create(:beis_organisation)
      ]
      user
    end

    before do
      authenticate!(user: user_with_additional_organisations)
    end
    after { logout }

    scenario "the other users' organisations on the user pages do not change to the switched organisation" do
      org1 = create(:partner_organisation)
      org2 = create(:partner_organisation)
      user1 = create(:partner_organisation_user, organisation: org1)
      create(:partner_organisation_user, organisation: org2)

      additional_org = user_with_additional_organisations.additional_organisations.first
      beis_org = user_with_additional_organisations.additional_organisations.last

      visit(root_path)

      # Switch to any other organisation...
      select(additional_org.name, from: "current_user_organisation")
      click_on t("organisation_switcher.submit")

      # Switch to BEIS/DSIT organisation so that users_path can be viewed
      select(beis_org.name, from: "current_user_organisation")
      click_on t("organisation_switcher.submit")

      visit(users_path)

      expect(page).to have_content org1.name
      expect(page).to have_content org2.name

      click_on "View #{user1.name}"
      expect(page.current_path).to eq user_path(user1)

      expect(page).to have_content org1.name
    end
  end

  context "when the user has no additional organisations" do
    let(:user) { create(:partner_organisation_user) }

    before { authenticate!(user:) }
    after { logout }

    scenario "the organisation switcher dropdown is not shown" do
      visit root_path

      expect(page).not_to have_content t("organisation_switcher.label")
    end
  end
end
