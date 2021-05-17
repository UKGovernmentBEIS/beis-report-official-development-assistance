RSpec.feature "BEIS users can view other organisations" do
  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      visit organisations_path
      expect(current_path).to eq(root_path)
    end
  end

  context "when the user belongs to BEIS" do
    let(:user) { create(:beis_user) }

    let!(:delivery_partner_organisations) { create_list(:delivery_partner_organisation, 3) }
    let!(:matched_effort_provider_organisations) { create_list(:matched_effort_provider, 2) }

    before do
      authenticate!(user: user)
    end

    context "when a role is provided" do
      before do
        visit organisations_path(role: role)
      end

      context "the role is 'delivery_partners'" do
        let(:role) { "delivery_partners" }

        scenario "it lists delivery partner organisations" do
          expect(page).to have_content(t("page_title.organisation.index"))

          delivery_partner_organisations.each do |organisation|
            expect(page).to have_content(organisation.name)
          end

          matched_effort_provider_organisations.each do |organisation|
            expect(page).to_not have_content(organisation.name)
          end
        end
      end

      context "the role is 'matched_effort_providers'" do
        let(:role) { "matched_effort_providers" }

        scenario "it lists matched effort provider organisations" do
          expect(page).to have_content(t("page_title.organisation.index"))

          matched_effort_provider_organisations.each do |organisation|
            expect(page).to have_content(organisation.name)
            expect(page).to have_content(organisation.beis_organisation_reference)
          end

          delivery_partner_organisations.each do |organisation|
            expect(page).to_not have_content(organisation.name)
          end
        end
      end
    end

    context "when the role is not provided" do
      before do
        visit organisations_path
      end

      scenario "it lists delivery partner organisations" do
        expect(page).to have_content(t("page_title.organisation.index"))

        delivery_partner_organisations.each do |organisation|
          expect(page).to have_content(organisation.name)
          expect(page).to have_content(organisation.beis_organisation_reference)
        end

        matched_effort_provider_organisations.each do |organisation|
          expect(page).to_not have_content(organisation.name)
        end
      end
    end
  end
end
