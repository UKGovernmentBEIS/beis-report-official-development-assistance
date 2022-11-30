require "csv"

RSpec.feature "BEIS users can upload Level B activities" do
  let(:organisation) { create(:partner_organisation) }
  let!(:newton_fund) { create(:fund_activity, :newton) }
  let!(:ispf) { create(:fund_activity, :ispf) }
  let(:user) { create(:beis_user) }

  before { authenticate!(user: user) }

  before do
    visit new_organisation_level_b_activities_upload_path(organisation)
  end

  after { logout }

  scenario "not uploading a file" do
    within ".upload-form--non-ispf" do
      click_button t("action.activity.upload.button")
    end

    expect(page).to have_text(t("action.activity.upload.file_missing_or_invalid"))
  end

  scenario "uploading an empty file" do
    within ".upload-form--non-ispf" do
      upload_empty_csv
    end

    expect(page).to have_text(t("action.activity.upload.file_missing_or_invalid"))
  end

  scenario "uploading a valid set of activities with a partner organisation identifier" do
    old_count = Activity.count

    csv = CSV.read("spec/fixtures/csv/valid_level_b_non_ispf_activities_upload.csv", headers: true)
    csv["Partner organisation identifier"] = ["example-id-1", "example-id-2"]
    csv_text = csv.to_s

    within ".upload-form--non-ispf" do
      upload_csv csv_text
    end

    expect(Activity.count - old_count).to eq(2)

    new_activities = [
      Activity.find_by(title: "Programme - Award (round 5)"),
      Activity.find_by(title: "Isolation and redesign of single-celled examples")
    ]

    visit organisation_activities_path(organisation)

    within "//tbody" do
      new_activities.each { |activity| expect(page).to have_content(activity.title) }
    end

    visit organisation_activity_comments_path(organisation, new_activities.first)

    expect(page).to have_text("A comment")

    visit organisation_activity_comments_path(organisation, new_activities.second)

    expect(page).to have_text("Another comment")
  end

  scenario "uploading a set of activities with a BOM at the start" do
    freeze_time do
      within ".upload-form--non-ispf" do
        attach_file_and_click_submit(filepath: "spec/fixtures/csv/valid_level_b_non_ispf_activities_upload.csv")
      end

      expect(page).to have_text(t("action.activity.upload.success"))

      new_activities = Activity.where(created_at: DateTime.now)

      expect(new_activities.count).to eq(2)
      expect(new_activities.pluck(:transparency_identifier)).to match_array(["1234", "1235"])
    end
  end

  scenario "uploading an invalid set of activities" do
    old_count = Activity.count

    within ".upload-form--non-ispf" do
      attach_file_and_click_submit(filepath: "spec/fixtures/csv/invalid_level_b_activities_upload.csv")
    end

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

    within ".upload-form--non-ispf" do
      upload_csv <<~CSV
        RODA ID                               | Title     | Sector | Benefitting Countries |
        #{activity_to_update.roda_identifier} | New Title | 11110  | BR                    |
      CSV
    end

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

    within ".upload-form--non-ispf" do
      upload_csv <<~CSV
        RODA ID                               | Title     | Sector | Partner Organisation Identifier |
        #{activity_to_update.roda_identifier} | New Title | 11110  | new-id-oh-no                    |
      CSV
    end

    expect(page).not_to have_text(t("action.activity.upload.success"))

    within "//tbody/tr[1]" do
      expect(page).to have_xpath("td[1]", text: "Partner organisation identifier")
      expect(page).to have_xpath("td[2]", text: "2")
      expect(page).to have_xpath("td[3]", text: "new-id-oh-no")
      expect(page).to have_xpath("td[4]", text: t("importer.errors.activity.cannot_update.partner_organisation_identifier_present"))
    end
  end

  scenario "upload a set of activities from the error page after a failed upload" do
    within ".upload-form--non-ispf" do
      upload_empty_csv
    end

    upload_empty_csv

    expect(page).to have_text(t("action.activity.upload.file_missing_or_invalid"))
  end

  context "ISPF ODA" do
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
        "ODA Eligibility",
        "Activity Status",
        "Planned start date",
        "Planned end date",
        "Actual start date",
        "Actual end date",
        "Sector",
        "Aid type",
        "Aims/Objectives",
        "ISPF themes",
        "ISPF partner countries",
        "Comments"
      ])
    end

    scenario "uploading a valid set of activities" do
      old_count = Activity.count

      within ".upload-form--ispf-oda" do
        attach_file_and_click_submit(filepath: "spec/fixtures/csv/valid_level_b_ispf_oda_activities_upload.csv")
      end

      expect(Activity.count - old_count).to eq(1)

      new_activity = Activity.find_by(title: "A title")

      visit organisation_activities_path(organisation)

      within "//tbody" do
        expect(page).to have_content(new_activity.title)
      end

      visit organisation_activity_comments_path(organisation, new_activity)

      expect(page).to have_text("This is a comment")
    end
  end

  context "ISPF non-ODA" do
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
        "Activity Status",
        "Planned start date",
        "Planned end date",
        "Actual start date",
        "Actual end date",
        "Sector",
        "ISPF themes",
        "ISPF partner countries",
        "Comments"
      ])
    end

    scenario "uploading a valid set of activities" do
      old_count = Activity.count

      within ".upload-form--ispf-non-oda" do
        attach_file_and_click_submit(filepath: "spec/fixtures/csv/valid_level_b_ispf_non_oda_activities_upload.csv")
      end

      expect(Activity.count - old_count).to eq(1)

      new_activity = Activity.find_by(title: "A title")

      visit organisation_activities_path(organisation)

      within "//tbody" do
        expect(page).to have_content(new_activity.title)
      end

      visit organisation_activity_comments_path(organisation, new_activity)

      expect(page).to have_text("This is a comment")
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
        "NF Partner Country PO",
        "Comments"
      ])
    end

    scenario "uploading a valid set of activities" do
      old_count = Activity.count

      within ".upload-form--non-ispf" do
        attach_file_and_click_submit(filepath: "spec/fixtures/csv/valid_level_b_non_ispf_activities_upload.csv")
      end

      expect(Activity.count - old_count).to eq(2)

      new_activities = [
        Activity.find_by(title: "Programme - Award (round 5)"),
        Activity.find_by(title: "Isolation and redesign of single-celled examples")
      ]

      visit organisation_activities_path(organisation)

      within "//tbody" do
        new_activities.each { |activity| expect(page).to have_content(activity.title) }
      end

      visit organisation_activity_comments_path(organisation, new_activities.first)

      expect(page).to have_text("A comment")

      visit organisation_activity_comments_path(organisation, new_activities.second)

      expect(page).to have_text("Another comment")
    end

    context "when the feature flag hiding ISPF is enabled for BEIS users" do
      before do
        mock_feature = double(:feature, groups: [:beis_users])
        allow(ROLLOUT).to receive(:get).and_return(mock_feature)
      end

      it "does not show the ISPF template download links" do
        visit new_organisation_level_b_activities_upload_path(organisation)

        expect(page).to_not have_content("ISPF")
        expect(page).to have_content("GCRF/NF/OODA")
      end
    end
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

  def attach_file_and_click_submit(filepath:)
    attach_file "organisation[activity_csv]", File.new(filepath).path
    click_button t("action.activity.upload.button")
  end

  def upload_csv(content)
    file = Tempfile.new("new_activities.csv")
    file.write(content.gsub(/ *\| */, ","))
    file.close

    attach_file_and_click_submit(filepath: file.path)

    file.unlink
  end

  def upload_empty_csv
    headings = Activity::Import.filtered_csv_column_headings(level: :level_b, type: :non_ispf)

    upload_csv(headings.join(", "))
  end
end
