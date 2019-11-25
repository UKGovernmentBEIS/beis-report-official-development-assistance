feature "Home page" do
  scenario "visit the home page" do
    visit root_path
    expect(page).to have_content(I18n.t("app.title"))
  end
end
