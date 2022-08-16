RSpec.feature "users can view a banner on non-production environments" do
  context "when on the staging site" do
    scenario "I see a banner informing me I am on the staging site" do
      ClimateControl.modify CANONICAL_HOSTNAME: "staging.report-official-development-assistance.service.gov.uk" do
        visit home_path

        within(".environment-info-wrapper") do
          expect(page).to have_content("staging")
        end
      end
    end
  end

  context "when on the training site" do
    scenario "I see a banner informing me I am on the training site" do
      ClimateControl.modify CANONICAL_HOSTNAME: "training.report-official-development-assistance.service.gov.uk" do
        visit home_path

        within(".environment-info-wrapper") do
          expect(page).to have_content("training")
        end
      end
    end
  end

  context "when on the production site" do
    scenario "I do not see a banner" do
      ClimateControl.modify CANONICAL_HOSTNAME: "www.report-official-development-assistance.service.gov.uk" do
        visit home_path

        expect(page).to_not have_selector(".environment-info-wrapper")
      end
    end
  end
end
