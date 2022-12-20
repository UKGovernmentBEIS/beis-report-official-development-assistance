require "rails_helper"

RSpec.describe Activity::Import do
  let(:organisation) { create(:partner_organisation) }
  let(:uploader) { create(:partner_organisation_user, organisation: organisation) }
  let(:fund_activity) { create(:fund_activity) }
  let(:report) { create(:report, fund: fund_activity) }
  let(:parent_activity) { create(:programme_activity, :newton_funded, extending_organisation: organisation) }
  let(:implementing_organisation_1) { create(:implementing_organisation) }
  let(:implementing_organisation_2) { create(:implementing_organisation) }
  let(:implementing_organisation_3) { create(:implementing_organisation) }

  let!(:existing_activity) do
    create(:project_activity) do |activity|
      activity.implementing_organisations = [implementing_organisation_1]
    end
  end

  let(:existing_activity_attributes) do
    {
      "RODA ID" => existing_activity.roda_identifier,
      "Transparency identifier" => "13232332323",
      "Parent RODA ID" => "",
      "Title" => "Here is a title",
      "Description" => "Some description goes here...",
      "Benefitting Countries" => "KH|KP|ID",
      "Partner organisation identifier" => "1234567890",
      "GDI" => "1",
      "GCRF Strategic Area" => "17A|RF",
      "GCRF Challenge Area" => "4",
      "SDG 1" => "1",
      "SDG 2" => "2",
      "SDG 3" => "3",
      "Covid-19 related research" => "0",
      "ODA Eligibility" => "0",
      "ODA Eligibility Lead" => "Bruce Wayne",
      "Newton Fund Pillar" => "1",
      "Activity Status" => "1",
      "Call open date" => "02/01/2020",
      "Call close date" => "02/01/2020",
      "Total applications" => "12",
      "Total awards" => "12",
      "Planned start date" => "02/01/2020",
      "Actual start date" => "03/01/2020",
      "Planned end date" => "04/01/2020",
      "Actual end date" => "05/01/2020",
      "Sector" => "11220",
      "Channel of delivery code" => "11000",
      "Collaboration type (Bi/Multi Marker)" => "1",
      "DFID policy marker - Gender" => "0",
      "DFID policy marker - Climate Change - Adaptation" => "2",
      "DFID policy marker - Climate Change - Mitigation" => "1",
      "DFID policy marker - Biodiversity" => "2",
      "DFID policy marker - Desertification" => "3",
      "DFID policy marker - Disability" => "",
      "DFID policy marker - Disaster Risk Reduction" => "0",
      "DFID policy marker - Nutrition" => "",
      "Aid type" => "B03",
      "Free Standing Technical Cooperation" => "1",
      "Aims/Objectives" => "Foo bar baz",
      "BEIS ID" => "BEIS_ID_EXAMPLE_01",
      "UK PO Named Contact" => "Jo Soap",
      "NF Partner Country PO" => "Association of Example Companies (AEC) | | Board of Sample Organisations (BSO)",
      "Implementing organisation names" => implementing_organisation_2.name,
      "Comments" => "Cat"
    }
  end

  let(:new_activity_attributes) do
    existing_activity_attributes.merge({
      "RODA ID" => "",
      "Parent RODA ID" => parent_activity.roda_identifier,
      "Transparency identifier" => "23232332323",
      "Implementing organisation names" => implementing_organisation_3.name,
      "Comments" => "Kitten"
    })
  end

  let(:activities) { [existing_activity_attributes, new_activity_attributes] }

  subject {
    Activity::Import.new(
      uploader: uploader,
      partner_organisation: organisation,
      report: report,
      is_oda: nil
    )
  }

  describe "::filtered_csv_column_headings" do
    context "Level B" do
      context "ISPF ODA" do
        it "returns the expected headings" do
          expect(Activity::Import.filtered_csv_column_headings(level: :level_b, type: :ispf_oda)).to eq([
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
            "Comments",
            "Tags"
          ])
        end
      end

      context "ISPF non-ODA" do
        it "returns the expected headings" do
          expect(Activity::Import.filtered_csv_column_headings(level: :level_b, type: :ispf_non_oda)).to eq([
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
            "Comments",
            "Tags"
          ])
        end
      end

      context "non-ISPF" do
        it "returns the expected headings" do
          expect(Activity::Import.filtered_csv_column_headings(level: :level_b, type: :non_ispf)).to eq([
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
            "Activity Status",
            "Planned start date",
            "Planned end date",
            "Actual start date",
            "Actual end date",
            "Sector",
            "Collaboration type (Bi/Multi Marker)",
            "Aid type",
            "Free Standing Technical Cooperation",
            "Aims/Objectives",
            "NF Partner Country PO",
            "Comments"
          ])
        end
      end
    end

    context "Level C/D" do
      context "ISPF ODA" do
        it "returns the expected headings" do
          expect(Activity::Import.filtered_csv_column_headings(level: :level_c_d, type: :ispf_oda)).to eq([
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
            "ISPF partner countries",
            "Comments",
            "Implementing organisation names",
            "Tags"
          ])
        end
      end

      context "ISPF non-ODA" do
        it "returns the expected headings" do
          expect(Activity::Import.filtered_csv_column_headings(level: :level_c_d, type: :ispf_non_oda)).to eq([
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
            "ISPF partner countries",
            "Comments",
            "Implementing organisation names",
            "Tags"
          ])
        end
      end

      context "non-ISPF" do
        it "returns the expected headings" do
          expect(Activity::Import.filtered_csv_column_headings(level: :level_c_d, type: :non_ispf)).to eq([
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
      end
    end
  end

  describe "::invalid_non_oda_attribute_errors" do
    let(:converted_level_b_oda_attributes) {
      {
        roda_identifier: "",
        linked_activity_id: "",
        transparency_identifier: "1234",
        title: "A title",
        description: "A description",
        benefitting_countries: "AO",
        partner_organisation_identifier: "",
        gdi: "4",
        sdg_1: "",
        sdg_2: "",
        sdg_3: "",
        oda_eligibility: "1",
        programme_status: "7",
        planned_start_date: "10/10/2020",
        planned_end_date: "10/10/2021",
        actual_start_date: "",
        actual_end_date: "",
        sector: "12182",
        aid_type: "D01",
        objectives: "Freetext objectives",
        ispf_themes: "1",
        ispf_partner_countries: "BR|EG",
        comments: "This is a comment"
      }
    }

    context "Level B" do
      let(:activity) { create(:programme_activity, :ispf_funded, is_oda: true) }
      let(:error_translation) { t("importer.errors.activity.oda_attribute_in_non_oda_activity") }

      it "returns a hash with errors where ODA fields have been included in a non-ODA upload" do
        expect(Activity::Import.invalid_non_oda_attribute_errors(
          activity: activity, converted_attributes: converted_level_b_oda_attributes
        )).to eq(
          {
            aid_type: ["D01", error_translation],
            benefitting_countries: ["AO", error_translation],
            gdi: ["4", error_translation],
            objectives: ["Freetext objectives", error_translation],
            oda_eligibility: ["1", error_translation]
          }
        )
      end
    end

    context "Level C/D" do
      let(:activity) { create(:project_activity, :ispf_funded, is_oda: true) }
      let(:error_translation) { t("importer.errors.activity.oda_attribute_in_non_oda_activity") }

      let(:converted_level_c_d_oda_attributes) {
        converted_level_b_oda_attributes.merge(
          {
            covid19_related: "1",
            oda_eligibility_lead: "ODA lead 1",
            call_open_date: "11/01/2019",
            call_close_date: "11/05/2019",
            total_applications: "14",
            total_awards: "5",
            channel_of_delivery_code: "11000",
            collaboration_type: "1",
            policy_marker_gender: "gender",
            policy_marker_climate_change_adaptation: "adaptation",
            policy_marker_climate_change_mitigation: "mitigation",
            policy_marker_biodiversity: "biodiversity",
            policy_marker_desertification: "desertification",
            policy_marker_disability: "disability",
            policy_marker_disaster_risk_reduction: "reduction",
            policy_marker_nutrition: "nutrition",
            fstc_applies: "0",
            uk_po_named_contact: "Someone Somebody"
          }
        )
      }

      it "returns a hash with errors where ODA fields have been included in a non-ODA upload" do
        expect(Activity::Import.invalid_non_oda_attribute_errors(
          activity: activity, converted_attributes: converted_level_c_d_oda_attributes
        )).to eq(
          {
            aid_type: ["D01", error_translation],
            benefitting_countries: ["AO", error_translation],
            channel_of_delivery_code: ["11000", error_translation],
            collaboration_type: ["1", error_translation],
            covid19_related: ["1", error_translation],
            fstc_applies: ["0", error_translation],
            gdi: ["4", error_translation],
            objectives: ["Freetext objectives", error_translation],
            oda_eligibility_lead: ["ODA lead 1", error_translation],
            policy_marker_biodiversity: ["biodiversity", error_translation],
            policy_marker_climate_change_adaptation: ["adaptation", error_translation],
            policy_marker_climate_change_mitigation: ["mitigation", error_translation],
            policy_marker_desertification: ["desertification", error_translation],
            policy_marker_disability: ["disability", error_translation],
            policy_marker_disaster_risk_reduction: ["reduction", error_translation],
            policy_marker_gender: ["gender", error_translation],
            policy_marker_nutrition: ["nutrition", error_translation]
          }
        )
      end
    end
  end

  describe "::is_oda_by_type" do
    context "when passed `:ispf_oda` as the type" do
      it "returns true" do
        expect(Activity::Import.is_oda_by_type(type: :ispf_oda)).to eq(true)
      end
    end

    context "when passed `:ispf_non_oda` as the type" do
      it "returns true" do
        expect(Activity::Import.is_oda_by_type(type: :ispf_non_oda)).to eq(false)
      end
    end

    context "when passed `:non_ispf` as the type" do
      it "returns nil" do
        expect(Activity::Import.is_oda_by_type(type: :non_ispf)).to eq(nil)
      end
    end
  end

  describe "#import" do
    before do
      allow(ActivityPolicy)
        .to receive(:new)
        .with(uploader, instance_of(Activity))
        .and_return(instance_double("ActivityPolicy", create_child?: true, update?: true))
    end

    it "calls `import_row` once per activity" do
      allow(subject).to receive(:import_row).and_return(nil)

      subject.import(activities)

      expect(subject).to have_received(:import_row).exactly(activities.count).times
      expect(subject).to have_received(:import_row).with(activities.first, 0)
      expect(subject).to have_received(:import_row).with(activities.second, 1)
    end

    context "when there are no errors" do
      it "creates and updates all activities" do
        allow(subject).to receive(:errors).and_return(nil)

        expect { subject.import(activities) }.to change { Activity.count }.by(2)

        new_activities = Activity.order(created_at: :desc).limit(2)

        imported_activity = new_activities.where(
          transparency_identifier: new_activity_attributes["Transparency identifier"]
        ).first

        expect(new_activities).to match_array([imported_activity, imported_activity.parent])

        expect(subject.created.count).to eq(1)

        expect(subject.updated.count).to eq(1)
        expect(existing_activity.reload.title).to eq(existing_activity_attributes["Title"])
      end
    end

    context "when there are errors" do
      it "doesn't create or update any activities" do
        allow(subject).to receive(:errors).and_return(double(["an error"]))

        subject.import(activities)

        expect(subject.created.count).to eq(0)

        expect(subject.updated.count).to eq(0)
        expect(existing_activity.reload.title).not_to eq(existing_activity_attributes[:title])
      end
    end
  end
end
