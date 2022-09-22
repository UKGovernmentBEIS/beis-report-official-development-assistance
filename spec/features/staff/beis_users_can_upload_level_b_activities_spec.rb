require "csv"

RSpec.feature "BEIS users can upload Level B activities" do
  let(:organisation) { create(:partner_organisation) }
  let!(:newton_fund) { create(:fund_activity, :newton) }
  let(:user) { create(:beis_user) }

  before { authenticate!(user: user) }

  before do
    visit new_organisation_level_b_activity_upload_path(organisation)
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
      "Collaboration type (Bi/Multi Marker)",
      "Aid type",
      "Free Standing Technical Cooperation",
      "Aims/Objectives",
      "NF Partner Country PO"
    ])
  end

  scenario "not uploading a file" do
    click_button t("action.activity.upload.button")

    expect(page).to have_text(t("action.activity.upload.file_missing_or_invalid"))
  end

  scenario "uploading an empty file" do
    upload_empty_csv

    expect(page).to have_text(t("action.activity.upload.file_missing_or_invalid"))
  end

  scenario "uploading a valid set of activities" do
    old_count = Activity.count

    # When I upload a valid Activity CSV
    attach_file "organisation[activity_csv]", File.new("spec/fixtures/csv/valid_level_b_activities_upload.csv").path
    click_button t("action.activity.upload.button")

    expect(Activity.count - old_count).to eq(2)

    visit organisation_activities_path(organisation)

    # And I should see the uploaded activities titles
    within "//tbody" do
      expect(page).to have_content("Programme - Award (round 5)")
      expect(page).to have_content("Isolation and redesign of single-celled examples")
    end
  end

  scenario "uploading a valid set of activities with a partner organisation identifier" do
    old_count = Activity.count

    csv = CSV.read("spec/fixtures/csv/valid_level_b_activities_upload.csv", headers: true)
    csv["Partner organisation identifier"] = ["example-id-1", "example-id-2"]
    csv_text = csv.to_s

    upload_csv csv_text

    expect(Activity.count - old_count).to eq(2)

    visit organisation_activities_path(organisation)

    within "//tbody" do
      expect(page).to have_content("Programme - Award (round 5)")
      expect(page).to have_content("Isolation and redesign of single-celled examples")
    end
  end

  scenario "uploading a set of activities with a BOM at the start" do
    freeze_time do
      attach_file "organisation[activity_csv]", File.new("spec/fixtures/csv/valid_level_b_activities_upload.csv").path
      click_button t("action.activity.upload.button")

      expect(page).to have_text(t("action.activity.upload.success"))

      new_activities = Activity.where(created_at: DateTime.now)

      expect(new_activities.count).to eq(2)
      expect(new_activities.pluck(:transparency_identifier)).to match_array(["1234", "1235"])
    end
  end

  scenario "uploading an invalid set of activities" do
    old_count = Activity.count

    attach_file "organisation[activity_csv]", File.new("spec/fixtures/csv/invalid_level_b_activities_upload.csv").path
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

  scenario "updating an existing activity" do
    activity_to_update = create(:fund_activity, :newton)

    upload_csv <<~CSV
      RODA ID                               | Title     | Sector | Benefitting Countries |
      #{activity_to_update.roda_identifier} | New Title | 11110  | BR                    |
    CSV

    expect(page).to have_text(t("action.activity.upload.success"))
    expect(page).to have_table(t("table.caption.activity.updated_activities"))

    expect_change_to_be_recorded_as_historical_event(
      field: "title",
      previous_value: activity_to_update.title,
      new_value: "New Title",
      activity: activity_to_update
    )

    expect_change_to_be_recorded_as_historical_event(
      field: "benefitting_countries",
      previous_value: activity_to_update.benefitting_countries,
      new_value: ["BR"],
      activity: activity_to_update
    )

    expect(activity_to_update.reload.title).to eq("New Title")

    within "//tbody/tr[1]" do
      expect(page).to have_xpath("td[2]", text: "New Title")
    end
  end

  scenario "attempting to change the partner organisation identifier of an existing activity" do
    activity_to_update = create(:project_activity, :gcrf_funded, organisation: organisation)

    upload_csv <<~CSV
      RODA ID                               | Title     | Sector | Partner Organisation Identifier |
      #{activity_to_update.roda_identifier} | New Title | 11110  | new-id-oh-no                    |
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

  def expect_change_to_be_recorded_as_historical_event(
    field:,
    previous_value:,
    new_value:,
    activity:
  )
    historical_event = HistoricalEvent.find_by!(value_changed: field)

    aggregate_failures do
      expect(historical_event.value_changed).to eq(field)
      expect(historical_event.previous_value).to eq(previous_value)
      expect(historical_event.new_value).to eq(new_value)
      expect(historical_event.reference).to eq("Import from CSV")
      expect(historical_event.user).to eq(user)
      expect(historical_event.activity).to eq(activity)
    end
  end

  def upload_csv(content)
    file = Tempfile.new("new_activities.csv")
    file.write(content.gsub(/ *\| */, ","))
    file.close

    attach_file "organisation[activity_csv]", file.path
    click_button t("action.activity.upload.button")

    file.unlink
  end

  def upload_empty_csv
    upload_csv(Activities::ImportFromCsv.column_headings.join(", "))
  end
end
