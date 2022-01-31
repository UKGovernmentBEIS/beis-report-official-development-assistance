RSpec.feature "users can upload activities" do
  let(:organisation) { create(:delivery_partner_organisation) }
  let(:user) { create(:delivery_partner_user, organisation: organisation) }

  let!(:programme) { create(:programme_activity, :newton_funded, extending_organisation: organisation, roda_identifier: "AFUND-B-PROG", parent: create(:fund_activity, roda_identifier: "AFUND")) }

  let!(:report) do
    create(:report,
      :active,
      fund: programme.associated_fund,
      organisation: organisation)
  end

  before do
    authenticate!(user: user)
    visit report_activities_path(report)
    click_link t("action.activity.upload.link")
  end

  scenario "downloading the CSV template" do
    click_link t("action.activity.download.button")

    csv_data = page.body.delete_prefix("\uFEFF")
    rows = CSV.parse(csv_data, headers: false).first

    expect(rows).to match_array([
      "RODA ID",
      "Activity Status",
      "Actual end date", "Actual start date",
      "Aid type",
      "Aims/Objectives (DP Definition)",
      "Call close date", "Call open date",
      "Channel of delivery code",
      "Collaboration type (Bi/Multi Marker)",
      "Covid-19 related research",
      "Description",
      "DFID policy marker - Biodiversity", "DFID policy marker - Climate Change - Adaptation",
      "DFID policy marker - Climate Change - Mitigation", "DFID policy marker - Desertification",
      "DFID policy marker - Disability", "DFID policy marker - Disaster Risk Reduction",
      "DFID policy marker - Gender", "DFID policy marker - Nutrition",
      "Delivery partner identifier",
      "Free Standing Technical Cooperation",
      "GCRF Strategic Area",
      "GCRF Challenge Area",
      "GDI",
      "Newton Fund Pillar",
      "ODA Eligibility", "ODA Eligibility Lead",
      "Parent RODA ID",
      "Planned end date", "Planned start date",
      "SDG 1", "SDG 2", "SDG 3",
      "Sector",
      "Title",
      "Total applications", "Total awards",
      "Transparency identifier",
      "UK DP Named Contact",
      "NF Partner Country DP",
      "Benefitting Countries"
    ])
  end

  scenario "not uploading a file" do
    click_button t("action.activity.upload.button")

    expect(page).to have_text(t("action.activity.upload.file_missing_or_invalid"))
  end

  scenario "uploading an empty file" do
    upload_csv(Activities::ImportFromCsv.column_headings.join(", "))

    expect(page).to have_text(t("action.activity.upload.file_missing_or_invalid"))
  end

  scenario "uploading a valid set of activities" do
    old_count = Activity.count

    attach_file "report[activity_csv]", File.new("spec/fixtures/csv/valid_activities_upload.csv").path
    click_button t("action.activity.upload.button")

    expect(Activity.count - old_count).to eq(2)
    expect(page).to have_text(t("action.activity.upload.success"))
    expect(page).to have_table(t("table.caption.activity.new_activities"))

    within "//tbody/tr[1]" do
      expect(page).to have_xpath("td[2]", text: "Programme - Award (round 5)")
    end

    within "//tbody/tr[2]" do
      expect(page).to have_xpath("td[2]", text: "Isolation and redesign of single-celled examples")
    end
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
    let(:another_organisation) { create(:delivery_partner_organisation) }
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

  scenario "attempting to change the delivery partner identifier of an existing activity" do
    activity_to_update = create(:project_activity, :gcrf_funded, organisation: organisation) { |activity|
      activity.implementing_organisations = [create(:implementing_organisation)]
    }
    create(:report, :active, fund: activity_to_update.associated_fund, organisation: organisation)

    upload_csv <<~CSV
      RODA ID                               | Title     | Channel of delivery code                       | Sector | Delivery Partner Identifier |
      #{activity_to_update.roda_identifier} | New Title | #{activity_to_update.channel_of_delivery_code} | 11110  | new-id-oh-no                |
    CSV

    expect(page).not_to have_text(t("action.activity.upload.success"))

    within "//tbody/tr[1]" do
      expect(page).to have_xpath("td[1]", text: "Delivery partner identifier")
      expect(page).to have_xpath("td[2]", text: "2")
      expect(page).to have_xpath("td[3]", text: "new-id-oh-no")
      expect(page).to have_xpath("td[4]", text: t("importer.errors.activity.cannot_update.delivery_partner_identifier_present"))
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
end
