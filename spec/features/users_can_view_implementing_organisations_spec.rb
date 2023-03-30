RSpec.feature "Users can view an organisation" do
  context "when the user does not belong to BEIS" do
    let(:organisation) { create(:partner_organisation) }
    let(:user) { create(:partner_organisation_user, organisation: organisation) }

    let!(:partner_organisations) { create_list(:partner_organisation, 3) }
    let!(:matched_effort_provider_organisations) { create_list(:matched_effort_provider, 2) }
    let!(:external_income_provider_organisations) { create_list(:external_income_provider, 2) }
    before do
      [
        {name: "Z_is_active", active: true},
        {name: "A_is_inactive", active: false}
      ].each do |attrs|
        create(:implementing_organisation).tap do |org|
          OrgParticipation.create(
            organisation: org,
            activity: create(:project_activity),
            role: "implementing"
          )
          org.active = attrs[:active]
          org.name = attrs[:name]
          org.save!
        end
      end
    end

    before do
      authenticate!(user: user)
    end

    after { logout }

    scenario "lists all organisations in the 'implementing' scope" do
      visit organisations_path
      expect(Organisation.implementing.count).to be >= 2

      within ".organisations" do
        Organisation.implementing.each do |org|
          expect(page).to have_content(org.name)
        end
      end
      expect(page).to have_css(".organisation", count: Organisation.implementing.count)

      within ".govuk-breadcrumbs" do
        expect(page).to have_content("Implementing organisations")
      end

      # check that inactive organisations come after active ones
      # despite alphabetical order
      expect(page.text).to match(/Z_is_active.*A_is_inactive/m)
    end

    scenario "does not list other types of organisation" do
      visit organisations_path

      expect(page).not_to have_content("Partner organisations")
      expect(page).not_to have_link(organisations_path(role: "external_income_providers"))
      expect(page).not_to have_link(organisations_path(role: "matched_effort_providers"))
    end
  end
end
