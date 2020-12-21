RSpec.feature "users can upload transactions" do
  let(:organisation) { create(:organisation) }
  let(:user) { create(:delivery_partner_user, organisation: organisation) }

  let!(:project) { create(:project_activity, organisation: organisation) }
  let!(:sibling_project) { create(:project_activity, organisation: organisation, parent: project.parent) }
  let!(:cousin_project) { create(:project_activity, organisation: organisation) }

  let! :report do
    create(:report,
      state: :active,
      fund: project.associated_fund,
      organisation: organisation)
  end

  before do
    authenticate!(user: user)
    visit report_path(report)
    click_link t("action.transaction.upload.link")
  end

  scenario "downloading a CSV template with activities for the current report" do
    click_link t("action.transaction.download.button")

    rows = CSV.parse(page.body, headers: true).map(&:to_h)

    expect(rows).to match_array([
      {
        "Activity Name" => project.title,
        "Activity Delivery Partner Identifier" => project.delivery_partner_identifier,
        "Activity RODA Identifier" => project.roda_identifier,
        "Date" => nil,
        "Value" => nil,
        "Receiving Organisation Name" => nil,
        "Receiving Organisation Type" => nil,
        "Receiving Organisation IATI Reference" => nil,
      },
      {
        "Activity Name" => sibling_project.title,
        "Activity Delivery Partner Identifier" => sibling_project.delivery_partner_identifier,
        "Activity RODA Identifier" => sibling_project.roda_identifier,
        "Date" => nil,
        "Value" => nil,
        "Receiving Organisation Name" => nil,
        "Receiving Organisation Type" => nil,
        "Receiving Organisation IATI Reference" => nil,
      },
    ])
  end

  scenario "not uploading a file" do
    click_button t("action.transaction.upload.button")
    expect(Transaction.count).to eq(0)
    expect(page).to have_text(t("action.transaction.upload.file_missing"))
  end

  scenario "uploading a valid set of transactions" do
    ids = [project, sibling_project].map(&:roda_identifier)

    upload_csv <<~CSV
      Activity RODA Identifier | Date       | Value | Receiving Organisation Name | Receiving Organisation Type | Receiving Organisation IATI Reference
      #{ids[0]}                | 2020-04-01 | 20    | Example University          | 80                          |
      #{ids[1]}                | 2020-04-02 | 30    | Example Foundation          | 60                          |
    CSV

    expect(Transaction.count).to eq(2)
    expect(page).to have_text(t("action.transaction.upload.success"))
    expect(page).not_to have_xpath("//tbody/tr")
  end

  scenario "uploading an invalid set of transactions" do
    ids = [project, sibling_project].map(&:roda_identifier)

    upload_csv <<~CSV
      Activity RODA Identifier | Date       | Value | Receiving Organisation Name | Receiving Organisation Type | Receiving Organisation IATI Reference
      #{ids[0]}                | 2020-04-01 | 0     | Example University          | 80                          |
      #{ids[1]}                | 2020-04-02 | 30    | Example Foundation          | 61                          |
    CSV

    expect(Transaction.count).to eq(0)
    expect(page).not_to have_text(t("action.transaction.upload.success"))

    within "//tbody/tr[1]" do
      expect(page).to have_xpath("td[1]", text: "Value")
      expect(page).to have_xpath("td[2]", text: "2")
      expect(page).to have_xpath("td[3]", text: "0")
      expect(page).to have_xpath("td[4]", text: t("activerecord.errors.models.transaction.attributes.value.other_than"))
    end

    within "//tbody/tr[2]" do
      expect(page).to have_xpath("td[1]", text: "Receiving Organisation Type")
      expect(page).to have_xpath("td[2]", text: "3")
      expect(page).to have_xpath("td[3]", text: "61")
      expect(page).to have_xpath("td[4]", text: t("importer.errors.transaction.invalid_iati_organisation_type"))
    end
  end

  scenario "uploading a set of transactions with encoding errors" do
    ids = [project, sibling_project].map(&:roda_identifier)

    upload_csv <<~CSV
      Activity RODA Identifier | Date       | Value  | Receiving Organisation Name | Receiving Organisation Type | Receiving Organisation IATI Reference
      #{ids[0]}                | 2020-04-01 | �20    | Example University          | 80                          |
      #{ids[1]}                | 2020-04-02 | �30    | Example Foundation          | 60                          |
    CSV

    expect(Transaction.count).to eq(0)

    within "//tbody/tr[1]" do
      expect(page).to have_xpath("td[1]", text: "Value")
      expect(page).to have_xpath("td[2]", text: "2")
      expect(page).to have_xpath("td[3]", text: "�20")
      expect(page).to have_xpath("td[4]", text: I18n.t("importer.errors.transaction.invalid_characters"))
    end

    within "//tbody/tr[2]" do
      expect(page).to have_xpath("td[1]", text: "Value")
      expect(page).to have_xpath("td[2]", text: "3")
      expect(page).to have_xpath("td[3]", text: "�30")
      expect(page).to have_xpath("td[4]", text: I18n.t("importer.errors.transaction.invalid_characters"))
    end
  end

  def upload_csv(content)
    file = Tempfile.new("transactions.csv")
    file.write(content.gsub(/ *\| */, ","))
    file.close

    attach_file "report[transaction_csv]", file.path
    click_button t("action.transaction.upload.button")

    file.unlink
  end
end
