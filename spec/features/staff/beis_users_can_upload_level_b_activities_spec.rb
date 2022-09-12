RSpec.feature "BEIS users can upload Level B activities" do
  let(:organisation) { create(:partner_organisation) }
  let(:user) { create(:beis_user) }
  before { authenticate!(user: user) }

  before do
    visit new_organisation_level_b_activity_upload_path(organisation)
  end

  scenario "viewing the page for downloading or uploading a CSV template" do
    expect(page).to have_content(t("page_title.activity.upload_level_b", organisation_name: organisation.name))
  end
end
