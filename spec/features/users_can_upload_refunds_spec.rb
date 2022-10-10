# NOTE:
# This spec primarily interacts with import_actuals and create_actual,
# rather than the non-existant import_actuals or the actually
# existing create_refund

RSpec.feature "users can upload refunds" do
  # Given that I am logged in as a partner organisation user,
  # And a report exists that is waiting for refunds to be uploaded
  let(:organisation) { create(:partner_organisation) }
  let(:user) { create(:partner_organisation_user, organisation: organisation) }
  #  only used for fund so far from project
  let(:project) { create(:project_activity, :newton_funded, organisation: organisation) } # was bang

  let :report do # was bang
    create(:report,
      :active,
      fund: project.associated_fund,
      organisation: organisation)
  end

  before do
    authenticate!(user: user)
    visit report_actuals_path(report)
  end

  after { logout }

  def upload_csv(content)
    file = Tempfile.new("actuals.csv")
    file.write(content.gsub(/ *\| */, ","))
    file.close

    attach_file "report[actual_csv]", file.path
    click_button t("action.actual.upload.button")

    file.unlink
  end

  scenario "Download a template CSV" do
    # When I download the Actuals & Refunds template CSV
    click_link t("page_content.actuals.button.download_template")
    # Then I see an Actual Value then a Refund Value column
    expect(page).to have_text(",Actual Value,Refund Value,")
  end

  scenario "Upload a valid refund" do
    click_link t("page_content.actuals.button.upload")
    id = project.roda_identifier

    # When I upload some refunds with comments
    upload_csv <<~CSV
      Activity RODA Identifier | Financial Quarter | Financial Year | Actual Value | Refund Value | Receiving Organisation Name | Receiving Organisation Type | Receiving Organisation IATI Reference | Comment
      #{id}                    | 1                 | 2020           |              | 1234.56      | Example University          | 80                          |                                       | Ocelot
    CSV

    # Then I see my refund amount and comment in the Refund section
    expect(page).to have_text("-£1,234.56")
    expect(page).to have_text("Ocelot")

    # When I go back to the Report and open the Comments tab
    click_on("Back to report")
    click_on("Comments")

    # Then I should see my Refunds comment is there
    expect(page).to have_text("Ocelot")
    expect(page).to have_text("Refund") # the type of the Comment

    # When I open the Actuals tab
    click_on("Actuals")

    # Then I should see my Refund amount and comment are there
    expect(page).to have_text("-£1,234.56")
    expect(page).to have_text("Ocelot")
  end

  scenario "Upload a valid refund with a zero actual" do
    click_link t("page_content.actuals.button.upload")
    id = project.roda_identifier

    # When I upload some refunds with comments
    upload_csv <<~CSV
      Activity RODA Identifier | Financial Quarter | Financial Year | Actual Value | Refund Value | Receiving Organisation Name | Receiving Organisation Type | Receiving Organisation IATI Reference | Comment
      #{id}                    | 1                 | 2020           | 0.00         | 1234.56      | Example University          | 80                          |                                       | Ocelot
    CSV

    # Then I see my refund amount and comment in the Refund section
    expect(page).to have_text("-£1,234.56")
    expect(page).to have_text("Ocelot")
  end

  scenario "Upload a row with both values" do
    # When I upload an Actuals & Refunds row which has a row with an Actual Value and Refund Value
    click_link t("page_content.actuals.button.upload")
    id = project.roda_identifier

    # When I upload some refunds with comments
    upload_csv <<~CSV
      Activity RODA Identifier | Financial Quarter | Financial Year | Actual Value | Refund Value | Receiving Organisation Name | Receiving Organisation Type | Receiving Organisation IATI Reference | Comment
      #{id}                    | 1                 | 2020           | 1234.56      | 42.00        | Example University          | 80                          |                                       | Refund 1234
    CSV

    # Then it shows an error for that row in the list of validation errors

    expect(page).to have_text("1234.56")
    expect(page).to have_text(t("importer.errors.actual.non_numeric_value")).once
  end
end
