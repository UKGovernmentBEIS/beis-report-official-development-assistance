RSpec.feature "JavaScript detection" do
  context "when JavaScript is enabled", js: true do
    scenario "the body element has a 'js-enabled' class" do
      visit root_path
      expect(page).to have_css("body.js-enabled")
    end
  end

  context "when JavaScript is disabled", js: false do
    scenario "the body element does not have a 'js-enabled' class" do
      visit root_path
      expect(page).not_to have_css("body.js-enabled")
    end
  end
end
