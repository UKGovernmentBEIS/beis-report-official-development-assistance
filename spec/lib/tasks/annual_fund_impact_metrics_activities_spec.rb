require "tempfile"
require "fileutils"

RSpec.describe "rake activities:annual_fund_impact_metrics", type: :task do
  subject { Rake::Task["activities:annual_fund_impact_metrics"] }

  let(:output_dir) { FileUtils.mkdir_p("tmp/annual_fund_impact_metrics") }
  let(:years) { [2021, 2022, 2023, 2024] }

  before { freeze_time }

  after do
    FileUtils.rm_rf(output_dir)
    subject.reenable
  end

  it "generates a CSV file of Level C and D activities for each organisation" do
    create(
      :project_activity,
      :with_actual,
      :newton_funded,
      title: "Completed Activity",
      roda_identifier: "ABC123",
      partner_organisation_identifier: "PORG1",
      programme_status: "completed",
      organisation: create(:partner_organisation, name: "Connected Places Catapult"),
      actual_attributes: {financial_year: 2024}
    )

    level_d_org = create(:partner_organisation, name: "Aardvark Org")
    create(
      :third_party_project_activity,
      :with_actual,
      :gcrf_funded,
      title: "Decided Activity",
      roda_identifier: "DEF123",
      partner_organisation_identifier: "PORG2",
      organisation: level_d_org,
      programme_status: "decided",
      actual_attributes: {financial_year: 2022}
    )
    create(
      :third_party_project_activity,
      :with_actual,
      :gcrf_funded,
      title: "Review Activity",
      roda_identifier: "GHI123",
      partner_organisation_identifier: "PORG3",
      organisation: level_d_org,
      programme_status: "review",
      actual_attributes: {financial_year: 2021}
    )

    task.invoke([2021, 2022, 2023, 2024])

    catapult_csv_path = File.join(output_dir, "connected-places-catapult_2021-2022-2023-2024.csv")
    aardvark_csv_path = File.join(output_dir, "aardvark-org_2021-2022-2023-2024.csv")

    expect(File.exist?(catapult_csv_path)).to be true
    expect(File.exist?(aardvark_csv_path)).to be true

    aardvark_csv_lines = File.readlines(aardvark_csv_path)
    expect(aardvark_csv_lines.count).to be 3
    expect(aardvark_csv_lines[0]).to eq "Partner Organisation name,Activity name,RODA ID,Partner Organisation ID,Fund,Status,Level\n"
    expect(aardvark_csv_lines[1]).to eq "Aardvark Org,Decided Activity,DEF123,PORG2,Global Challenges Research Fund,Decided,Third-party project (level D)\n"
    expect(aardvark_csv_lines[2]).to eq "Aardvark Org,Review Activity,GHI123,PORG3,Global Challenges Research Fund,Review,Third-party project (level D)\n"

    catapult_csv_lines = File.readlines(catapult_csv_path)
    expect(catapult_csv_lines.count).to be 2
    expect(catapult_csv_lines[0]).to eq "Partner Organisation name,Activity name,RODA ID,Partner Organisation ID,Fund,Status,Level\n"
    expect(catapult_csv_lines[1]).to eq "Connected Places Catapult,Completed Activity,ABC123,PORG1,Newton Fund,Completed,Project (level C)\n"
  end

  describe "selecting the right activity level" do
    context "when selecting activities from the list of specified partner organisations" do
      it "only selects Level C activities" do
        level_c_orgs = [
          "Connected Places Catapult",
          "Energy Systems Catapult",
          "Offshore Renewable Energy Catapult",
          "National Physics Laboratory",
          "UK Atomic Energy Authority"
        ]

        level_c_orgs.each do |partner_organisation|
          organisation = create(:partner_organisation, name: partner_organisation)
          level_c_completed_activity = create(:project_activity, programme_status: "completed", organisation:)
          create(:actual, financial_year: 2024, parent_activity: level_c_completed_activity)
          level_d_completed_activity = create(:third_party_project_activity, programme_status: "completed", organisation:)
          create(:actual, financial_year: 2024, parent_activity: level_d_completed_activity)
        end

        task.invoke([2021, 2022, 2023, 2024])
        files = level_c_orgs.map do |org|
          File.join(output_dir, "#{org.parameterize}_2021-2022-2023-2024.csv")
        end

        all_level_c_activities_present = files.all? do |file|
          file_contains_activity_with_value(file, "Project (level C)")
        end
        expect(all_level_c_activities_present).to be(true)

        no_level_d_activities_present = files.none? do |file|
          file_contains_activity_with_value(file, "Third-party project (level D)")
        end
        expect(no_level_d_activities_present).to eq(true)
      end

      it "finds the Organisations case-insensitively" do
        upper_case_org = create(:partner_organisation, name: "CONNECTED PLACES CATAPULT")
        create(
          :project_activity,
          :with_actual,
          programme_status: "completed",
          organisation: upper_case_org,
          actual_attributes: {financial_year: 2021}
        )
        lower_case_org = create(:partner_organisation, name: "energy systems catapult")
        create(
          :project_activity,
          :with_actual,
          programme_status: "completed",
          organisation: lower_case_org,
          actual_attributes: {financial_year: 2021}
        )

        task.invoke([2021, 2022, 2023, 2024])

        cpc_file = File.join(output_dir, "connected-places-catapult_2021-2022-2023-2024.csv")
        expect(file_contains_activity_with_value(
          cpc_file,
          "Connected Places Catapult"
        )).to eq(true)

        esc_file = File.join(output_dir, "energy-systems-catapult_2021-2022-2023-2024.csv")
        expect(file_contains_activity_with_value(
          esc_file,
          "Energy Systems Catapult"
        )).to eq(true)
      end
    end

    context "when selecting activities from any other organisation" do
      it "only selects Level D activities" do
        partner_organisation = create(:partner_organisation, name: "My Org")
        create(
          :project_activity,
          :with_actual,
          programme_status: "completed",
          organisation: partner_organisation,
          actual_attributes: {financial_year: 2024}
        )
        create(
          :third_party_project_activity,
          :with_actual,
          programme_status: "completed",
          organisation: partner_organisation,
          actual_attributes: {financial_year: 2024}
        )

        task.invoke([2021, 2022, 2023, 2024])
        file = File.join(output_dir, "my-org_2021-2022-2023-2024.csv")

        expect(
          file_contains_activity_with_value(file, "Project (level C)")
        ).to eq(false)

        expect(
          file_contains_activity_with_value(file, "Third-party project (level D)")
        ).to eq(true)
      end
    end
  end

  describe "specifying financial years" do
    context "when financial years are not provided" do
      it "displays an error and aborts" do
        expect {
          task.invoke
        }.to raise_error(
          SystemExit,
          "Please provide at least one financial year, e.g. rake 'activities:annual_fund_impact_metrics[2022,2023]'"
        )
      end
    end

    context "when financial years are provided" do
      it "only includes projects with postive net spend in the specified financial years" do
        partner_organisation = create(:partner_organisation, name: "My Org")
        [2021, 2022, 2023, 2024].each do |fy|
          create(
            :third_party_project_activity,
            :with_actual,
            organisation: partner_organisation,
            programme_status: "completed",
            actual_attributes: {financial_year: fy}
          )
        end

        activity_with_actual_from_2020 = create(
          :third_party_project_activity,
          :with_actual,
          organisation: partner_organisation,
          programme_status: "completed",
          actual_attributes: {financial_year: 2020}
        )

        task.invoke([2021, 2022, 2023, 2024])

        file = File.join(output_dir, "my-org_2021-2022-2023-2024.csv")

        expect(File.readlines(file).length).to eq(5)
        expect(file_contains_activity_with_value(
          file,
          activity_with_actual_from_2020.roda_identifier
        )).to be(false)
      end
    end
  end

  it "excludes Activities with `delivery`, `agreement_in_place`, `open_for_applications`, `stopped`, or `planned` statuses" do
    partner_organisation = create(:partner_organisation, name: "My Org")
    completed_activity = create(
      :third_party_project_activity,
      :with_actual,
      programme_status: "completed",
      organisation: partner_organisation,
      actual_attributes: {financial_year: 2021}
    )
    delivery_activity = create(
      :third_party_project_activity,
      :with_actual,
      programme_status: "delivery",
      organisation: partner_organisation,
      actual_attributes: {financial_year: 2021}
    )
    agreement_in_place_activity = create(
      :third_party_project_activity,
      :with_actual,
      programme_status: "agreement_in_place",
      organisation: partner_organisation,
      actual_attributes: {financial_year: 2021}
    )
    open_for_applications_activity = create(
      :third_party_project_activity,
      :with_actual,
      programme_status: "open_for_applications",
      organisation: partner_organisation,
      actual_attributes: {financial_year: 2021}
    )
    stopped_activity = create(
      :third_party_project_activity,
      :with_actual,
      programme_status: "stopped",
      organisation: partner_organisation,
      actual_attributes: {financial_year: 2021}
    )
    planned_activity = create(
      :third_party_project_activity,
      :with_actual,
      programme_status: "planned",
      organisation: partner_organisation,
      actual_attributes: {financial_year: 2021}
    )

    task.invoke([2021, 2022, 2023, 2024])

    file = File.join(output_dir, "my-org_2021-2022-2023-2024.csv")

    expect(
      file_contains_activity_with_value(
        file,
        completed_activity.roda_identifier
      )
    ).to eq(true)

    excluded_activities = [
      delivery_activity,
      agreement_in_place_activity,
      open_for_applications_activity,
      stopped_activity,
      planned_activity
    ]

    excluded_activities_present = excluded_activities.map(&:roda_identifier).any? { |id|
      file_contains_activity_with_value(file, id)
    }
    expect(excluded_activities_present).to be(false)
  end

  it "excludes Activities with no Actuals" do
    partner_organisation = create(:partner_organisation, name: "My Org")
    completed_activity = create(
      :third_party_project_activity,
      :with_actual,
      programme_status: "completed",
      organisation: partner_organisation,
      actual_attributes: {financial_year: 2021}
    )

    completed_activity_with_no_actual = create(
      :third_party_project_activity,
      programme_status: "completed",
      organisation: partner_organisation
    )

    task.invoke(2021, 2022, 2023, 2024)

    file = File.join(output_dir, "my-org_2021-2022-2023-2024.csv")

    expect(
      file_contains_activity_with_value(file, completed_activity.roda_identifier)
    ).to eq(true)

    expect(
      file_contains_activity_with_value(
        file,
        completed_activity_with_no_actual.roda_identifier
      )
    ).to eq(false)
  end

  def file_contains_activity_with_value(file_path, value)
    csv_lines = File.readlines(file_path)

    csv_lines.any? do |activity|
      activity.include?(value)
    end
  end
end
