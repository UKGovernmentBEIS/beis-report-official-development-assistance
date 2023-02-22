RSpec.feature "users can upload activities" do
  let(:organisation) { create(:partner_organisation) }
  let(:user) { create(:partner_organisation_user, organisation: organisation) }

  let!(:programme) { create(:programme_activity, :newton_funded, extending_organisation: organisation, roda_identifier: "AFUND-B-PROG", parent: create(:fund_activity, roda_identifier: "AFUND")) }
  let!(:report) { create(:report, fund: programme.associated_fund, organisation: organisation) }

  let!(:oda_programme) {
    create(:programme_activity,
      :ispf_funded,
      roda_identifier: "ISPF-ODA-PROGRAMME-ID",
      extending_organisation: organisation,
      is_oda: true,
      title: "A linked oda programme")
  }

  let!(:non_oda_programme) {
    create(:programme_activity,
      :ispf_funded,
      roda_identifier: "ISPF-NON-ODA-PROGRAMME-ID",
      extending_organisation: organisation,
      is_oda: false,
      title: "A linked oda programme",
      linked_activity: oda_programme)
  }

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

  context "uploading a valid template in the wrong form" do
    let(:report) { create(:report, fund: non_oda_programme.associated_fund, organisation: organisation) }

    scenario "uploading a template with ODA-specific fields via the non-ODA form" do
      old_count = Activity.count

      within ".upload-form--ispf-non-oda" do
        attach_file "report[activity_csv]", File.new("spec/fixtures/csv/valid_ispf_oda_activities_upload.csv").path
        click_button t("action.activity.upload.button")
      end

      expect(Activity.count - old_count).to eq(0)
      expect(page).not_to have_text(t("action.activity.upload.success"))

      within "//tbody/tr[1]" do
        expect(page).to have_xpath("td[1]", text: "Benefitting Countries")
        expect(page).to have_xpath("td[2]", text: "2")
        expect(page).to have_xpath("td[3]", text: '["AO"]')
        expect(page).to have_xpath("td[4]", text: t("importer.errors.activity.oda_attribute_in_non_oda_activity"))
      end

      within "//tbody/tr[2]" do
        expect(page).to have_xpath("td[1]", text: "GDI")
        expect(page).to have_xpath("td[2]", text: "2")
        expect(page).to have_xpath("td[3]", text: "4")
        expect(page).to have_xpath("td[4]", text: t("importer.errors.activity.oda_attribute_in_non_oda_activity"))
      end

      within "//tbody/tr[3]" do
        expect(page).to have_xpath("td[1]", text: "ODA Eligibility Lead")
        expect(page).to have_xpath("td[2]", text: "2")
        expect(page).to have_xpath("td[3]", text: "ODA lead 1")
        expect(page).to have_xpath("td[4]", text: t("importer.errors.activity.oda_attribute_in_non_oda_activity"))
      end

      within "//tbody/tr[4]" do
        expect(page).to have_xpath("td[1]", text: "Channel of delivery code")
        expect(page).to have_xpath("td[2]", text: "2")
        expect(page).to have_xpath("td[3]", text: "11000")
        expect(page).to have_xpath("td[4]", text: t("importer.errors.activity.oda_attribute_in_non_oda_activity"))
      end

      within "//tbody/tr[5]" do
        expect(page).to have_xpath("td[1]", text: "Collaboration type (Bi/Multi Marker)")
        expect(page).to have_xpath("td[2]", text: "2")
        expect(page).to have_xpath("td[3]", text: "1")
        expect(page).to have_xpath("td[4]", text: t("importer.errors.activity.oda_attribute_in_non_oda_activity"))
      end

      within "//tbody/tr[6]" do
        expect(page).to have_xpath("td[1]", text: "Aid type")
        expect(page).to have_xpath("td[2]", text: "2")
        expect(page).to have_xpath("td[3]", text: "D02")
        expect(page).to have_xpath("td[4]", text: t("importer.errors.activity.oda_attribute_in_non_oda_activity"))
      end

      within "//tbody/tr[7]" do
        expect(page).to have_xpath("td[1]", text: "Free Standing Technical Cooperation")
        expect(page).to have_xpath("td[2]", text: "2")
        expect(page).to have_xpath("td[3]", text: "0")
        expect(page).to have_xpath("td[4]", text: t("importer.errors.activity.oda_attribute_in_non_oda_activity"))
      end

      within "//tbody/tr[8]" do
        expect(page).to have_xpath("td[1]", text: "Aims/Objectives")
        expect(page).to have_xpath("td[2]", text: "2")
        expect(page).to have_xpath("td[3]", text: "Freetext objectives")
        expect(page).to have_xpath("td[4]", text: t("importer.errors.activity.oda_attribute_in_non_oda_activity"))
      end

      within "//tbody/tr[9]" do
        expect(page).to have_xpath("td[1]", text: "ISPF ODA partner countries")
        expect(page).to have_xpath("td[2]", text: "2")
        expect(page).to have_xpath("td[3]", text: '["BR", "EG"]')
        expect(page).to have_xpath("td[4]", text: t("importer.errors.activity.oda_attribute_in_non_oda_activity"))
      end
    end
  end

  context "ISPF ODA" do
    let!(:non_oda_project) {
      create(:project_activity,
        :ispf_funded,
        roda_identifier: "ISPF-NON-ODA-PROJECT-ID",
        extending_organisation: organisation,
        is_oda: false,
        title: "A linked non oda project",
        parent: non_oda_programme)
    }

    let(:report) { create(:report, fund: oda_programme.associated_fund, organisation: organisation) }

    scenario "downloading the CSV template" do
      click_link t("action.activity.download.link", type: t("action.activity.type.ispf_oda"))

      csv_data = page.body.delete_prefix("\uFEFF")
      rows = CSV.parse(csv_data, headers: false).first

      expect(rows).to eq([
        "RODA ID",
        "Parent RODA ID",
        "Linked activity RODA ID",
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
        "ISPF themes",
        "ISPF ODA partner countries",
        "ISPF non-ODA partner countries",
        "Implementing organisation names",
        "Tags",
        "Comments"
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

      # When I visit the details page of an activity with tags
      click_on "Details"

      # Then I should see the tags
      expect(page).to have_content("Ayrton Fund")
      expect(page).to have_content("ICF Funded")
    end

    scenario "linking an activity to a non-ODA activity via the bulk upload" do
      within ".upload-form--ispf-oda" do
        attach_file "report[activity_csv]", File.new("spec/fixtures/csv/valid_ispf_oda_activities_upload_with_linked_non_oda_activity.csv").path
        click_button t("action.activity.upload.button")
      end

      activity_link = within("tbody") { page.find(:css, "a")["href"] }

      visit activity_link

      within ".govuk-summary-list.activity-summary .linked_activity" do
        expect(page).to have_content("A linked non oda project")
      end
    end
  end

  context "ISPF non-ODA" do
    let!(:oda_project) {
      create(:project_activity,
        :ispf_funded,
        roda_identifier: "ISPF-ODA-PROJECT-ID",
        extending_organisation: organisation,
        is_oda: true,
        title: "A linked oda project",
        parent: oda_programme)
    }

    let(:report) { create(:report, fund: non_oda_programme.associated_fund, organisation: organisation) }

    scenario "downloading the CSV template" do
      click_link t("action.activity.download.link", type: t("action.activity.type.ispf_non_oda"))

      csv_data = page.body.delete_prefix("\uFEFF")
      rows = CSV.parse(csv_data, headers: false).first

      expect(rows).to eq([
        "RODA ID",
        "Parent RODA ID",
        "Linked activity RODA ID",
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
        "ISPF themes",
        "ISPF non-ODA partner countries",
        "Implementing organisation names",
        "Tags",
        "Comments"
      ])
    end

    scenario "uploading a valid set of activities" do
      old_count = Activity.count

      # When I upload a valid Activity CSV with comments
      within ".upload-form--ispf-non-oda" do
        attach_file "report[activity_csv]", File.new("spec/fixtures/csv/valid_ispf_non_oda_activities_upload.csv").path
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

      # When I visit the details page of an activity with tags
      click_on "Details"

      # Then I should see the tags
      expect(page).to have_content("ICF Funded")
      expect(page).to have_content("Tactical Fund")
    end

    scenario "linking an activity to a ODA activity via the bulk upload" do
      within ".upload-form--ispf-non-oda" do
        attach_file "report[activity_csv]", File.new("spec/fixtures/csv/valid_ispf_non_oda_activities_upload_with_linked_oda_activity.csv").path
        click_button t("action.activity.upload.button")
      end

      activity_link = within("tbody") { page.find(:css, "a")["href"] }

      visit activity_link

      within ".govuk-summary-list.activity-summary .linked_activity" do
        expect(page).to have_content("A linked oda project")
      end
    end
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
        "Implementing organisation names",
        "Comments"
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
