RSpec.feature "BEIS users can view other organisations" do
  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      visit organisations_path
      expect(current_path).to eq(root_path)
    end
  end

  context "when the user belongs to BEIS" do
    let(:user) { create(:beis_user) }

    scenario "all organisations can be viewed" do
      another_organisation = create(:organisation)
      authenticate!(user: user)

      visit organisations_path

      expect(page).to have_content(t("page_title.organisation.index"))
      expect(page).to have_content(user.organisation.name)
      expect(page).to have_content(another_organisation.name)
    end
  end
end
