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

  scenario "downloading the CSV template" do
    click_link t("action.activity.bulk_download.button")

    csv_data = page.body.delete_prefix("\uFEFF")
    rows = CSV.parse(csv_data, headers: false).first

    expect(rows).to match_array([
      "RODA ID",
      "Parent RODA ID",
      "Transparency identifier",
      "Title",
      "Description",
      "Benefitting Countries",
      "Partner organisation identifier",
      "GDI",
      "GCRF Strategic Area",
      "GCRF Challenge Area",
      "SDG 1", "SDG 2", "SDG 3",
      "Newton Fund Pillar",
      "Covid-19 related research",
      "ODA Eligibility",
      "Activity Status",
      "Planned start date", "Planned end date",
      "Actual start date", "Actual end date",
      "Sector",
      "Channel of delivery code",
      "Collaboration type (Bi/Multi Marker)",
      "Aid type",
      "Free Standing Technical Cooperation",
      "Aims/Objectives (PO Definition)",
      "NF Partner Country PO"
    ])
  end
end
