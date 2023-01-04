require "rails_helper"

RSpec.describe Activity::Import::Converter do
  let(:organisation) { create(:partner_organisation) }
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
      "Partner organisation identifier" => "1234567890",
      "Implementing organisation names" => implementing_organisation_3.name,
      "Comments" => "Kitten"
    })
  end

  let(:row) { new_activity_attributes }

  subject { Activity::Import::Converter.new(row: row) }

  describe "#raw" do
    it "returns the row's value for given attribute" do
    end
  end

  describe "#to_h" do
    it "sets sector category" do
    end

    it "ignores columns marked for exclusion from the converter" do
      # roda_identifier
      # parent_id
      # comments
      # implementing_organisation_names
    end

    it "ignores blank columns unless they're allowed to be blank" do
    end

    it "converts values to stripped strings in the absence of a bespoke converter" do
    end

    context "for fields with bespoke converters" do
      context "ISPF-specific fields" do
        # convert_linked_activity_id - this one needs to be handled differently

        # these can be handled as below, but we need to modify the subject to set `is_oda` and add the values to the row
        # convert_ispf_themes
        # convert_ispf_partner_countries
        # convert_tags
      end

      bespoke_converter_fields = [
        {attribute: :benefitting_countries, converted_value: %w[KH KP ID], invalid_value: "UK|SC"},
        {attribute: :gdi, converted_value: "1", invalid_value: "0"},
        {attribute: :gcrf_strategic_area, converted_value: %w[17A RF], invalid_value: "XX|YY"},
        {attribute: :gcrf_challenge_area, converted_value: 4, invalid_value: "99"},
        {attribute: :sdg_1, converted_value: "1", invalid_value: "99", error_message: I18n.t("importer.errors.activity.invalid_sdg")},
        {attribute: :sdg_2, converted_value: "2", invalid_value: "99", error_message: I18n.t("importer.errors.activity.invalid_sdg")},
        {attribute: :sdg_3, converted_value: "3", invalid_value: "99", error_message: I18n.t("importer.errors.activity.invalid_sdg")},
        {attribute: :fund_pillar, converted_value: "1", invalid_value: "99"},
        {attribute: :covid19_related, converted_value: "0", invalid_value: "99"},
        {attribute: :oda_eligibility, converted_value: "never_eligible", invalid_value: "99"},
        {attribute: :programme_status, converted_value: "delivery", invalid_value: "99"},
        {attribute: :call_open_date, converted_value: DateTime.new(2020, 1, 2), invalid_value: "not a date"},
        {attribute: :call_close_date, converted_value: DateTime.new(2020, 1, 2), invalid_value: "not a date"},
        {attribute: :planned_start_date, converted_value: DateTime.new(2020, 1, 2), invalid_value: "not a date"},
        {attribute: :planned_end_date, converted_value: DateTime.new(2020, 1, 4), invalid_value: "not a date"},
        {attribute: :actual_start_date, converted_value: DateTime.new(2020, 1, 3), invalid_value: "not a date"},
        {attribute: :actual_end_date, converted_value: DateTime.new(2020, 1, 5), invalid_value: "not a date"},
        {attribute: :sector, converted_value: "11220", invalid_value: "XXXXX"},
        {attribute: :channel_of_delivery_code, converted_value: "11000", invalid_value: "XXXXX"},
        {attribute: :collaboration_type, converted_value: "1", invalid_value: "0"},
        {attribute: :policy_marker_gender, converted_value: "not_targeted", invalid_value: "not an integer", error_message: I18n.t("importer.errors.activity.invalid_policy_marker")},
        {attribute: :policy_marker_climate_change_adaptation, converted_value: "principal_objective", invalid_value: "99", error_message: I18n.t("importer.errors.activity.invalid_policy_marker")},
        {attribute: :policy_marker_climate_change_mitigation, converted_value: "significant_objective", invalid_value: "not an integer", error_message: I18n.t("importer.errors.activity.invalid_policy_marker")},
        {attribute: :policy_marker_biodiversity, converted_value: "principal_objective", invalid_value: "99", error_message: I18n.t("importer.errors.activity.invalid_policy_marker")},
        {attribute: :policy_marker_disability, converted_value: nil, invalid_value: "not an integer", error_message: I18n.t("importer.errors.activity.invalid_policy_marker")},
        {attribute: :policy_marker_disaster_risk_reduction, converted_value: "not_targeted", invalid_value: "99", error_message: I18n.t("importer.errors.activity.invalid_policy_marker")},
        {attribute: :policy_marker_nutrition, converted_value: nil, invalid_value: "not an integer", error_message: I18n.t("importer.errors.activity.invalid_policy_marker")},
        {attribute: :policy_marker_desertification, converted_value: "principal_objective_and_in_support_of_an_action_programme", invalid_value: "99", error_message: I18n.t("importer.errors.activity.invalid_policy_marker")},
        {attribute: :aid_type, converted_value: "B03", invalid_value: "X99"},
        {attribute: :fstc_applies, converted_value: "1", invalid_value: "99"}
      ]

      context "when valid" do
        it "sets the values and has no errors" do
          bespoke_converter_fields.each do |field|
            expect(subject.to_h[field[:attribute]]).to eq(field[:converted_value])
          end

          expect(subject.to_h[:country_partner_organisations]).to eq(["Association of Example Companies (AEC)", "Board of Sample Organisations (BSO)"])

          expect(subject.errors).to be_empty
        end
      end

      context "when invalid" do
        invalid_values = bespoke_converter_fields.to_h do |field|
          heading = ACTIVITY_CSV_COLUMNS.dig(field[:attribute], :heading)

          [heading, field[:invalid_value]]
        end

        let(:row) { new_activity_attributes.merge(invalid_values) }

        it "adds all relevant error messages" do
          bespoke_converter_fields.each do |field|
            error_message = field[:error_message] || I18n.t("importer.errors.activity")[:"invalid_#{field[:attribute]}"]

            expect(subject.errors[field[:attribute]]).to eq([field[:invalid_value], error_message])
          end

          expect(subject.errors.length).to eq(bespoke_converter_fields.length)
        end
      end
    end

    context "when creating" do
      it "sets call present" do
      end
    end

    context "when updating" do
      subject { Activity::Import::Converter.new(row: existing_activity_attributes, method: :update) }

      context "and a column is blank" do
      end
    end
  end
end
