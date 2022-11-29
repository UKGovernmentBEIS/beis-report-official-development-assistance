RSpec.feature "users can upload activities" do
  let(:organisation) { create(:partner_organisation) }
  let(:user) { create(:partner_organisation_user, organisation: organisation) }

  let!(:programme) { create(:programme_activity, :newton_funded, extending_organisation: organisation, roda_identifier: "AFUND-B-PROG", parent: create(:fund_activity, roda_identifier: "AFUND")) }
  let!(:report) { create(:report, fund: programme.associated_fund, organisation: organisation) }

  before do
    # Given I'm logged in as a PO
    authenticate!(user: user)

    # And I am on the Activities Upload page
    visit report_activities_path(report)
    click_link t("page_content.activities.button.upload")
  end

  after { logout }

  scenario "not uploading a file" do
    click_button t("action.activity.upload.button")

    expect(page).to have_text(t("action.activity.upload.file_missing_or_invalid"))
  end

  scenario "uploading an empty file" do
    upload_empty_csv

    expect(page).to have_text(t("action.activity.upload.file_missing_or_invalid"))
  end

  scenario "uploading a set of activities with a BOM at the start" do
    freeze_time do
      attach_file "report[activity_csv]", File.new("spec/fixtures/csv/excel_upload.csv").path
      click_button t("action.activity.upload.button")

      expect(page).to have_text(t("action.activity.upload.success"))

      new_activities = Activity.where(created_at: DateTime.now)

      expect(new_activities.count).to eq(2)

      expect(new_activities.pluck(:transparency_identifier)).to match_array(["1234", "1235"])
    end
  end

  scenario "uploading an invalid set of activities" do
    old_count = Activity.count

    attach_file "report[activity_csv]", File.new("spec/fixtures/csv/invalid_activities_upload.csv").path
    click_button t("action.activity.upload.button")

    expect(Activity.count - old_count).to eq(0)
    expect(page).not_to have_text(t("action.activity.upload.success"))

    within "//tbody/tr[1]" do
      expect(page).to have_xpath("td[1]", text: "Benefitting Countries")
      expect(page).to have_xpath("td[2]", text: "2")
      expect(page).to have_xpath("td[3]", text: "ZZ")
      expect(page).to have_xpath("td[4]", text: t("importer.errors.activity.invalid_benefitting_countries"))
    end

    within "//tbody/tr[2]" do
      expect(page).to have_xpath("td[1]", text: "Free Standing Technical Cooperation")
      expect(page).to have_xpath("td[2]", text: "3")
      expect(page).to have_xpath("td[3]", text: "")
      expect(page).to have_xpath("td[4]", text: t("activerecord.errors.models.activity.attributes.fstc_applies.inclusion"))
    end
  end

  context "uploading a set of activities the user doesn't have permission to modify" do
    let(:another_organisation) { create(:partner_organisation) }
    let!(:another_programme) { create(:programme_activity, parent: programme.associated_fund, extending_organisation: another_organisation, roda_identifier: "AFUND-BB-PROG") }
    let!(:existing_activity) { create(:project_activity, parent: programme, roda_identifier: "AFUND-B-PROG-EX42") }

    it "prevents creating or updating" do
      old_count = Activity.count

      attach_file "report[activity_csv]", File.new("spec/fixtures/csv/unpermitted_activities_upload.csv").path
      click_button t("action.activity.upload.button")

      expect(Activity.count - old_count).to eq(0)
      expect(page).not_to have_text(t("action.activity.upload.success"))

      within "//tbody/tr[1]" do
        expect(page).to have_xpath("td[1]", text: "Parent RODA ID")
        expect(page).to have_xpath("td[2]", text: "2")
        expect(page).to have_xpath("td[3]", text: "")
        expect(page).to have_xpath("td[4]", text: t("importer.errors.activity.unauthorised"))
      end

      within "//tbody/tr[2]" do
        expect(page).to have_xpath("td[1]", text: "RODA ID")
        expect(page).to have_xpath("td[2]", text: "3")
        expect(page).to have_xpath("td[3]", text: "")
        expect(page).to have_xpath("td[4]", text: t("importer.errors.activity.unauthorised"))
      end
    end
  end

  scenario "updating an existing activity" do
    activity_to_update = create(:project_activity, :gcrf_funded, organisation: organisation) { |activity|
      activity.implementing_organisations = [create(:implementing_organisation)]
    }
    create(:report, :active, fund: activity_to_update.associated_fund, organisation: organisation)

    upload_csv <<~CSV
      RODA ID                               | Title     | Channel of delivery code                       | Sector | Benefitting Countries |
      #{activity_to_update.roda_identifier} | New Title | #{activity_to_update.channel_of_delivery_code} | 11110  | BR                    |
    CSV

    expect(page).to have_text(t("action.activity.upload.success"))
    expect(page).to have_table(t("table.caption.activity.updated_activities"))

    expect_change_to_be_recorded_as_historical_event(
      field: "title",
      previous_value: activity_to_update.title,
      new_value: "New Title",
      activity: activity_to_update,
      report: report
    )

    expect_change_to_be_recorded_as_historical_event(
      field: "benefitting_countries",
      previous_value: activity_to_update.benefitting_countries,
      new_value: ["BR"],
      activity: activity_to_update,
      report: report
    )

    expect(activity_to_update.reload.title).to eq("New Title")

    within "//tbody/tr[1]" do
      expect(page).to have_xpath("td[2]", text: "New Title")
    end
  end

  scenario "attempting to change the partner organisation identifier of an existing activity" do
    activity_to_update = create(:project_activity, :gcrf_funded, organisation: organisation) { |activity|
      activity.implementing_organisations = [create(:implementing_organisation)]
    }
    create(:report, :active, fund: activity_to_update.associated_fund, organisation: organisation)

    upload_csv <<~CSV
      RODA ID                               | Title     | Channel of delivery code                       | Sector | Partner Organisation Identifier |
      #{activity_to_update.roda_identifier} | New Title | #{activity_to_update.channel_of_delivery_code} | 11110  | new-id-oh-no                |
    CSV

    expect(page).not_to have_text(t("action.activity.upload.success"))

    within "//tbody/tr[1]" do
      expect(page).to have_xpath("td[1]", text: "Partner organisation identifier")
      expect(page).to have_xpath("td[2]", text: "2")
      expect(page).to have_xpath("td[3]", text: "new-id-oh-no")
      expect(page).to have_xpath("td[4]", text: t("importer.errors.activity.cannot_update.partner_organisation_identifier_present"))
    end
  end

  scenario "upload a set of activities from the error page after a failed upload" do
    2.times { upload_empty_csv }

    expect(page).to have_text(t("action.activity.upload.file_missing_or_invalid"))
  end

  context "GCRF/Newton/OODA" do
    scenario "downloading the CSV template" do
      click_link t("action.activity.download.link", type: t("action.activity.type.non_ispf"))

      csv_data = page.body.delete_prefix("\uFEFF")
      rows = CSV.parse(csv_data, headers: false).first

      expect(rows).to eq([
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
        "SDG 1",
        "SDG 2",
        "SDG 3",
        "Newton Fund Pillar",
        "Covid-19 related research",
        "ODA Eligibility",
        "ODA Eligibility Lead",
        "Activity Status",
        "Call open date",
        "Call close date",
        "Total applications",
        "Total awards",
        "Planned start date",
        "Planned end date",
        "Actual start date",
        "Actual end date",
        "Sector",
        "Channel of delivery code",
        "Collaboration type (Bi/Multi Marker)",
        "DFID policy marker - Gender",
        "DFID policy marker - Climate Change - Adaptation",
        "DFID policy marker - Climate Change - Mitigation",
        "DFID policy marker - Biodiversity",
        "DFID policy marker - Desertification",
        "DFID policy marker - Disability",
        "DFID policy marker - Disaster Risk Reduction",
        "DFID policy marker - Nutrition",
        "Aid type",
        "Free Standing Technical Cooperation",
        "Aims/Objectives",
        "UK PO Named Contact",
        "NF Partner Country PO",
        "Comments",
        "Implementing organisation names"
      ])
    end

    scenario "uploading a valid set of activities" do
      old_count = Activity.count

      # When I upload a valid Activity CSV with comments
      attach_file "report[activity_csv]", File.new("spec/fixtures/csv/valid_non_ispf_activities_upload.csv").path
      click_button t("action.activity.upload.button")

      expect(Activity.count - old_count).to eq(2)
      # Then I should see confirmation that I have uploaded new activities
      expect(page).to have_text(t("action.activity.upload.success"))
      expect(page).to have_table(t("table.caption.activity.new_activities"))

      # And I should see the uploaded activities titles
      within "//tbody/tr[1]" do
        expect(page).to have_xpath("td[2]", text: "Programme - Award (round 5)")
      end

      within "//tbody/tr[2]" do
        expect(page).to have_xpath("td[2]", text: "Isolation and redesign of single-celled examples")
      end

      activity_links = within("tbody") { page.find_all(:css, "a").map { |a| a["href"] } }

      # When I visit an activity with a comment
      visit activity_links.first
      click_on "Comments"

      # Then I should see the comment body
      expect(page).to have_content("A comment")
      expect(page).to have_content("Comment reported in")

      # When I visit an activity which had an empty comment in the CSV
      visit activity_links.last
      click_on "Comments"

      # Then I should see that there are no comments
      expect(page).not_to have_content("Comment reported in")
    end
  end

  context "ISPF ODA" do
    let(:programme) { create(:programme_activity, :ispf_funded, extending_organisation: organisation, roda_identifier: "ISPF-B-PROG") }
    let(:report) { create(:report, fund: programme.associated_fund, organisation: organisation) }

    scenario "downloading the CSV template" do
      click_link t("action.activity.download.link", type: t("action.activity.type.ispf_oda"))

      csv_data = page.body.delete_prefix("\uFEFF")
      rows = CSV.parse(csv_data, headers: false).first

      expect(rows).to eq([
        "RODA ID",
        "Parent RODA ID",
        "Transparency identifier",
        "Title",
        "Description",
        "Benefitting Countries",
        "Partner organisation identifier",
        "GDI",
        "SDG 1",
        "SDG 2",
        "SDG 3",
        "Covid-19 related research",
        "ODA Eligibility",
        "ODA Eligibility Lead",
        "Activity Status",
        "Call open date",
        "Call close date",
        "Total applications",
        "Total awards",
        "Planned start date",
        "Planned end date",
        "Actual start date",
        "Actual end date",
        "Sector",
        "Channel of delivery code",
        "Collaboration type (Bi/Multi Marker)",
        "DFID policy marker - Gender",
        "DFID policy marker - Climate Change - Adaptation",
        "DFID policy marker - Climate Change - Mitigation",
        "DFID policy marker - Biodiversity",
        "DFID policy marker - Desertification",
        "DFID policy marker - Disability",
        "DFID policy marker - Disaster Risk Reduction",
        "DFID policy marker - Nutrition",
        "Aid type",
        "Free Standing Technical Cooperation",
        "Aims/Objectives",
        "UK PO Named Contact",
        "ISPF theme",
        "ISPF partner countries",
        "Comments",
        "Implementing organisation names"
      ])
    end

    scenario "uploading a valid set of activities" do
      old_count = Activity.count

      # When I upload a valid Activity CSV with comments
      within ".upload-form--ispf-oda" do
        attach_file "report[activity_csv]", File.new("spec/fixtures/csv/valid_ispf_oda_activities_upload.csv").path
        click_button t("action.activity.upload.button")
      end

      expect(Activity.count - old_count).to eq(1)
      # Then I should see confirmation that I have uploaded a new activity
      expect(page).to have_text(t("action.activity.upload.success"))
      expect(page).to have_table(t("table.caption.activity.new_activities"))

      # And I should see the uploaded activities titles
      within "//tbody/tr[1]" do
        expect(page).to have_xpath("td[2]", text: "A title")
      end

      activity_link = within("tbody") { page.find(:css, "a")["href"] }

      # When I visit an activity with a comment
      visit activity_link
      click_on "Comments"

      # Then I should see the comment body
      expect(page).to have_content("A comment")
    end
  end

  context "ISPF non-ODA" do
    let(:programme) { create(:programme_activity, :ispf_funded, extending_organisation: organisation, roda_identifier: "ISPF-B-PROG") }
    let(:report) { create(:report, fund: programme.associated_fund, organisation: organisation) }

    scenario "downloading the CSV template" do
      click_link t("action.activity.download.link", type: t("action.activity.type.ispf_non_oda"))

      csv_data = page.body.delete_prefix("\uFEFF")
      rows = CSV.parse(csv_data, headers: false).first

      expect(rows).to eq([
        "RODA ID",
        "Parent RODA ID",
        "Transparency identifier",
        "Title",
        "Description",
        "Partner organisation identifier",
        "SDG 1",
        "SDG 2",
        "SDG 3",
        "ODA Eligibility",
        "Activity Status",
        "Call open date",
        "Call close date",
        "Total applications",
        "Total awards",
        "Planned start date",
        "Planned end date",
        "Actual start date",
        "Actual end date",
        "Sector",
        "UK PO Named Contact",
        "ISPF theme",
        "ISPF partner countries",
        "Comments",
        "Implementing organisation names"
      ])
    end
  end

  def expect_change_to_be_recorded_as_historical_event(
    field:,
    previous_value:,
    new_value:,
    activity:,
    report:
  )
    historical_event = HistoricalEvent.find_by!(value_changed: field)

    aggregate_failures do
      expect(historical_event.value_changed).to eq(field)
      expect(historical_event.previous_value).to eq(previous_value)
      expect(historical_event.new_value).to eq(new_value)
      expect(historical_event.reference).to eq("Import from CSV")
      expect(historical_event.user).to eq(user)
      expect(historical_event.activity).to eq(activity)
      expect(historical_event.report).to eq(report)
    end
  end

  def upload_csv(content)
    file = Tempfile.new("new_activities.csv")
    file.write(content.gsub(/ *\| */, ","))
    file.close

    attach_file "report[activity_csv]", file.path
    click_button t("action.activity.upload.button")

    file.unlink
  end

  def upload_empty_csv
    headings = Activity::Import.filtered_csv_column_headings(level: :level_c_d, type: :non_ispf)

    upload_csv(headings.join(", "))
  end
end
