RSpec.feature "BEIS users can view other organisations" do
  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      visit organisations_path
      expect(current_path).to eq(root_path)
    end
  end

  RSpec.shared_examples "lists delivery partner organisations" do
    scenario "it lists delivery partner organisations" do
      expect(page).to have_content(t("page_title.organisation.index"))
      expect(page).to have_content(t("page_title.organisations.delivery_partners"))

      expect(page.find("li.govuk-tabs__list-item--selected a.govuk-tabs__tab")).to have_text(t("tabs.organisations.delivery_partners"))

      delivery_partner_organisations.each do |organisation|
        expect(page).to have_content(organisation.beis_organisation_reference)
        expect(page).to have_content(organisation.name)
      end

      matched_effort_provider_organisations.each do |organisation|
        expect(page).to_not have_content(organisation.name)
      end
    end
  end

  RSpec.shared_examples "lists matched effort provider organisations" do
    scenario "it lists matched effort provider organisations" do
      expect(page).to have_content(t("page_title.organisation.index"))
      expect(page.find("li.govuk-tabs__list-item--selected a.govuk-tabs__tab")).to have_text(t("tabs.organisations.matched_effort_providers"))
      expect(page).to have_content(t("page_title.organisations.matched_effort_providers"))

      matched_effort_provider_organisations.each do |organisation|
        expect(page).to have_content(organisation.name)
      end

      delivery_partner_organisations.each do |organisation|
        expect(page).to_not have_content(organisation.name)
      end
    end
  end

  RSpec.shared_examples "lists external income provider organisations" do
    scenario "it lists external income provider organisations" do
      expect(page).to have_content(t("page_title.organisation.index"))
      expect(page.find("li.govuk-tabs__list-item--selected a.govuk-tabs__tab")).to have_text(t("tabs.organisations.external_income_providers"))
      expect(page).to have_content(t("page_title.organisations.external_income_providers"))

      matched_effort_provider_organisations.each do |organisation|
        expect(page).to_not have_content(organisation.name)
      end

      delivery_partner_organisations.each do |organisation|
        expect(page).to_not have_content(organisation.name)
      end

      external_income_provider_organisations.each do |organisation|
        expect(page).to have_content(organisation.name)
      end
    end
  end

  context "when the user belongs to BEIS" do
    let(:user) { create(:beis_user) }

    let!(:delivery_partner_organisations) { create_list(:delivery_partner_organisation, 3) }
    let!(:matched_effort_provider_organisations) { create_list(:matched_effort_provider, 2) }
    let!(:external_income_provider_organisations) { create_list(:external_income_provider, 2) }
    let!(:implementing_organisations) do
      2.times {
        create(:implementing_organisation).tap do |org|
          OrgParticipation.create(
            organisation: org,
            activity: create(:project_activity),
            role: "implementing"
          )
        end
      }
    end

    before do
      authenticate!(user: user)
    end

    context "when a role is provided" do
      before do
        visit organisations_path(role: role)
      end

      context "the role is 'implementing_organisations'" do
        let(:role) { "implementing_organisations" }

        scenario "lists all organisations in the 'implementing' scope" do
          expect(Organisation.implementing.count).to be >= 2

          within ".organisations" do
            Organisation.implementing.each do |org|
              expect(page).to have_content(org.name)
            end
          end
          expect(page).to have_css(".organisation", count: Organisation.implementing.count)
          then_breadcrumb_shows_type_of_organisation(name: "Implementing organisations")
        end
      end

      context "the role is 'delivery_partners'" do
        let(:role) { "delivery_partners" }

        include_examples "lists delivery partner organisations"

        context "when viewing the matched effort providers tab" do
          before do
            click_on t("tabs.organisations.matched_effort_providers")
          end

          it "includes type of organisation in breadcrumb" do
            then_breadcrumb_shows_type_of_organisation(name: "Matched effort providers")
          end

          include_examples "lists matched effort provider organisations"
        end

        context "when viewing the external income providers tab" do
          before do
            click_on t("tabs.organisations.external_income_providers")
          end

          it "includes type of organisation in breadcrumb" do
            then_breadcrumb_shows_type_of_organisation(name: "External income providers")
          end

          include_examples "lists external income provider organisations"
        end
      end

      context "the role is 'matched_effort_providers'" do
        let(:role) { "matched_effort_providers" }

        include_examples "lists matched effort provider organisations"

        context "when viewing the delivery partner organisations tab" do
          before do
            click_on t("tabs.organisations.delivery_partners")
          end

          include_examples "lists delivery partner organisations"
        end

        context "when viewing the external income providers tab" do
          before do
            click_on t("tabs.organisations.external_income_providers")
          end

          include_examples "lists external income provider organisations"
        end
      end

      context "the role is 'external_income_providers'" do
        let(:role) { "external_income_providers" }

        include_examples "lists external income provider organisations"

        context "when viewing the delivery partner organisations tab" do
          before do
            click_on t("tabs.organisations.delivery_partners")
          end

          include_examples "lists delivery partner organisations"
        end

        context "when viewing the matched effort providers tab" do
          before do
            click_on t("tabs.organisations.matched_effort_providers")
          end

          include_examples "lists matched effort provider organisations"
        end
      end
    end

    context "when the role is not provided" do
      before do
        visit organisations_path
      end

      include_examples "lists delivery partner organisations"
    end

    def then_breadcrumb_shows_type_of_organisation(name:)
      within ".govuk-breadcrumbs" do
        expect(page).to have_content(name)
      end
    end
  end
end
