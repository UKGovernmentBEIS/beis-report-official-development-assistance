RSpec.feature "users can upload refunds" do
  # Given that I am logged in as a Delivery Partner,
  # And a report exists that is waiting for refunds to be uploaded
  let(:organisation) { create(:delivery_partner_organisation) }
  let(:user) { create(:delivery_partner_user, organisation: organisation) }
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

  scenario "Upload a refund" do
    click_link t("page_content.actuals.button.upload")
    id = project.roda_identifier

    # When I upload some refunds with comments
    upload_csv <<~CSV
      Activity RODA Identifier | Financial Quarter | Financial Year | Actual Value | Refund Value | Receiving Organisation Name | Receiving Organisation Type | Receiving Organisation IATI Reference | Comment
      #{id}                    | 1                 | 2020           |              | 1234.56      | Example University          | 80                          |                                       | Refund 1234
    CSV

    # Then I see my refunds in the Refund section
    expect(page).to have_text("1,234.56")
    expect(page).to have_text("Refund 1234")
  end

  # When I upload an Actuals & Refunds CSV with a refund and comments,
  # Then I should see a summary of my refund with comments,

  # When I go back to the Report,
  # And I open the Comments tab,
  # Then I should see my Refunds comment is there.
  # When I open the Actuals tab
  # Then I should see my Refunds in there.

  # When I download the Actuals & Refunds template CSV
  # Then I see an Actual Value and Refund Value column

  # When I upload an Actuals & Refunds row which has a row with an Actual Value and Refund Value
  # Then it shows an error for that row in the list of validation errors

  # When I upload an Actuals & Refunds row which has a Refund Value and a Comment
  # We can see the refund exists
end
