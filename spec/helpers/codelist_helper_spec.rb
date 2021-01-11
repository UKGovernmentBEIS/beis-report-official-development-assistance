require "rails_helper"

RSpec.describe CodelistHelper, type: :helper do
  describe "version 2_03" do
    let(:version) { "2_03" }

    describe "#yaml_to_objects" do
      it "raises an error when the YAML file is missing or incorrect" do
        expect { helper.yaml_to_objects(entity: "generic", type: "favourite_colours") }
          .to raise_error "CodelistHelper::UnreadableCodelist"
      end

      it "formats the data in a yaml file to an array of objects for use in govuk form builder" do
        expect(helper.yaml_to_objects(entity: "generic", type: "default_currency"))
          .to include(
            OpenStruct.new(name: "Afghani", code: "AFN"),
            OpenStruct.new(name: "Lek", code: "ALL"),
            OpenStruct.new(name: "Armenian Dram", code: "AMD"),
            OpenStruct.new(name: "Netherlands Antillian Guilder", code: "ANG"),
            OpenStruct.new(name: "Kwanza", code: "AOA")
          )
      end

      it "adds a blank first item by default" do
        expect(helper.yaml_to_objects(
          entity: "generic",
          type: "default_currency"
        ).first).to eq(OpenStruct.new(name: "", code: ""))
      end

      it "removes the blank first item if you need it to" do
        expect(helper.yaml_to_objects(
          entity: "generic",
          type: "default_currency",
          with_empty_item: false
        ).first).to_not eq(OpenStruct.new(name: "", code: ""))
      end

      it "sorts the resulting objects by name order" do
        expect(helper.yaml_to_objects(
          entity: "generic",
          type: "default_currency",
          with_empty_item: false
        ).first).to eq(OpenStruct.new(name: "Afghani", code: "AFN"))
        expect(helper.yaml_to_objects(
          entity: "generic",
          type: "default_currency",
          with_empty_item: false
        ).last).to eq(OpenStruct.new(name: "Zloty", code: "PLN"))
      end

      context "when there are three 'withdrawn' items and one 'active' item" do
        let(:fake_yaml) { YAML.safe_load(File.read("#{Rails.root}/spec/fixtures/codelist_with_withdrawn_items.yml")) }
        before do
          allow(helper).to receive(:load_yaml).and_return(fake_yaml["data"])
        end

        it "only adds the 'active' item to the final list" do
          list = helper.yaml_to_objects(
            entity: "activity",
            type: "sector",
            with_empty_item: false
          )

          expect(list.count).to eq(1)
          expect(list.first.name).to eq("Active code")
        end
      end

      it "does not add any duplicate-named items to the list" do
        list = helper.yaml_to_objects(
          entity: "activity",
          type: "sector",
          with_empty_item: false
        )
        grouped_by_name = list.group_by { |item| item["name"] }
        duplicate_groups = grouped_by_name.values.select { |a| a.size > 1 }.flatten
        expect(duplicate_groups.count).to eql(0)
      end
    end

    describe "#yaml_to_objects_with_description" do
      it "raises an error when the YAML file is missing or incorrect" do
        expect { helper.yaml_to_objects_with_description(entity: "generic", type: "favourite_colours") }
          .to raise_error "CodelistHelper::UnreadableCodelist"
      end

      it "formats the data in a yaml file to an array of objects for use in govuk form builder, with descriptions" do
        expect(helper.yaml_to_objects_with_description(entity: "activity", type: "status"))
          .to include(
            OpenStruct.new(name: "Pipeline/identification", code: "1", description: "The activity is being scoped or planned"),
            OpenStruct.new(name: "Implementation", code: "2", description: "The activity is currently being implemented"),
            OpenStruct.new(name: "Completion", code: "3", description: "Physical activity is complete or the final disbursement has been made"),
            OpenStruct.new(name: "Post-completion", code: "4", description: "Physical activity is complete or the final disbursement has been made, but the activity remains open pending financial sign off or M&E"),
            OpenStruct.new(name: "Cancelled", code: "5", description: "The activity has been cancelled"),
            OpenStruct.new(name: "Suspended", code: "6", description: "The activity has been temporarily suspended")
          )
      end

      it "sorts the data by code order" do
        expect(helper.yaml_to_objects_with_description(
          entity: "activity",
          type: "status"
        ).first).to eq(OpenStruct.new(name: "Pipeline/identification", code: "1", description: "The activity is being scoped or planned"))
        expect(helper.yaml_to_objects_with_description(
          entity: "activity",
          type: "status"
        ).last).to eq(OpenStruct.new(name: "Suspended", code: "6", description: "The activity has been temporarily suspended"))
      end

      it "tries to get a description from the translations if one is available" do
        objects = helper.yaml_to_objects_with_description(entity: "activity", type: "aid_type")

        expect(objects.find { |o| o["code"] == "B02" }.description).to eq(t("form.hint.activity.options.aid_type.B02"))
        expect(objects.find { |o| o["code"] == "E01" }.description).to eq("Financial aid awards for individual students and contributions to trainees.")
      end
    end

    describe "#currency_select_options" do
      it "returns an array of objects with GBP as the first (default) option" do
        expect(helper.currency_select_options.first)
          .to eq(OpenStruct.new(name: "Pound Sterling", code: "GBP"))
      end
    end

    describe "#region_select_options" do
      it "returns an array of region objects with 998 as the first (default) option" do
        expect(helper.region_select_options.first)
          .to eq(OpenStruct.new(name: "Developing countries, unspecified", code: "998"))
      end
    end

    describe "#region_name_from_code" do
      it "returns the name of the region from a code number" do
        expect(helper.region_name_from_code("998")).to eq("Developing countries, unspecified")
      end
    end

    describe "#country_select_options" do
      it "returns an array of country objects with '' as the first (default) option" do
        expect(helper.country_select_options.first)
          .to eq(OpenStruct.new(name: t("page_content.activity.recipient_country.default_selection_value"), code: ""))
      end
    end

    describe "#country_name_from_code" do
      it "returns the name of the country from a code number" do
        expect(helper.country_name_from_code("DZ")).to eq("Algeria")
      end
    end

    describe "#collaboration_type_radio_options" do
      it "returns the different options for collaboration type sorted by code" do
        options = helper.collaboration_type_radio_options

        expect(options.length).to eq 7
        expect(options.first.code).to eq "1"
        expect(options.first.name).to eq "Bilateral"
        expect(options.last.code).to eq "8"
        expect(options.last.name).to eq "Bilateral, triangular co-operation"
      end
    end

    describe "#flow_select_options" do
      it "returns an array of flow objects with 10 as the first (default) option" do
        expect(helper.flow_select_options.first)
          .to eq(OpenStruct.new(name: "ODA", code: "10"))
      end
    end

    describe "#sector_radio_options" do
      it "returns all sectors when no category is passed" do
        options = helper.sector_radio_options

        expect(options.length).to eq 294
        expect(options).to include OpenStruct.new(name: "Women’s rights organisations and movements, and government institutions", code: "15170", category: "151")
        expect(options).to include OpenStruct.new(name: "Action relating to debt", code: "60010", category: "600")
      end

      it "returns only the sectors from the category when one is passed" do
        options = helper.sector_radio_options(category: 112)

        expect(options.length).to eq 6
        expect(options).to include OpenStruct.new(name: "Basic life skills for youth", code: "11231", category: "112")
        expect(options).to include OpenStruct.new(name: "School feeding", code: "11250", category: "112")
        expect(options).not_to include OpenStruct.new(name: "Immediate post-emergency reconstruction and rehabilitation", code: "73010", category: "730")
      end
    end

    describe "#all_sectors" do
      it "returns all the sectors including those that are withdrawn" do
        sectors = helper.all_sectors
        active_sector = OpenStruct.new(name: "Basic life skills for youth", code: "11231", category: "112")
        withdrawn_sector = OpenStruct.new(name: "Disaster prevention and preparedness", code: "74010", category: "740")

        expect(sectors).to include active_sector
        expect(sectors).to include withdrawn_sector
      end
    end

    describe "#aid_type_radio_options" do
      it "returns the aid type with the code appended to the name" do
        options = helper.aid_type_radio_options

        expect(options.length).to eq 7
        expect(options.first.name).to eq "Core contributions to multilateral institutions (B02)"
        expect(options.last.name).to eq "Administrative costs not included elsewhere (G01)"
      end
    end

    describe "#policy_markers_select_options" do
      it "returns the options for policy markers, prepending the BEIS custom option" do
        options = helper.policy_markers_select_options

        expect(options.length).to eq 5
        expect(options.first.name).to eq("Not assessed")
        expect(options.first.code).to eq("1000")
        expect(options.last.name).to eq("Principal objective AND in support of an action programme")
        expect(options.last.code).to eq("3")
      end
    end

    describe "#intended_beneficiaries_checkbox_options" do
      it "returns a full list of all countries" do
        options = helper.intended_beneficiaries_checkbox_options

        expect(options.length).to eq 143
        expect(options.first.name).to eq("Afghanistan")
        expect(options.last.name).to eq("Zimbabwe")
      end
    end

    describe "#fstc_from_aid_type" do
      it "returns nil if the aid type is not set" do
        expect(helper.fstc_from_aid_type(nil)).to be_nil
      end

      it "returns true for D02" do
        expect(helper.fstc_from_aid_type("D02")).to eql true
      end

      it "returns true for E01" do
        expect(helper.fstc_from_aid_type("E01")).to eql true
      end

      it "returns false for G01" do
        expect(helper.fstc_from_aid_type("G01")).to eql false
      end

      it "returns nil for any other aid type" do
        expect(helper.fstc_from_aid_type("B02")).to be_nil
      end
    end

    describe "#can_infer_fstc?" do
      it "returns false if the aid type is not set" do
        expect(helper.can_infer_fstc?(nil)).to eql false
      end

      it "returns true for aid types 'D02', 'E01', 'G01'" do
        %w[D02 E01 G01].each do |at|
          expect(helper.can_infer_fstc?(at)).to eql true
        end
      end

      it "returns false for any other aid type" do
        (CodelistHelper::ALLOWED_AID_TYPE_CODES - %w[D02 E01 G01]).each do |at|
          expect(helper.can_infer_fstc?(at)).to eql false
        end
      end
    end
  end

  describe "BEIS" do
    describe "#oda_eligibility_radio_options" do
      it "returns the radio options and hints for ODA eligibility" do
        options = helper.oda_eligibility_radio_options

        expect(options.length).to eq 3
        expect(options.first.label).to eq("No - was never eligible")
        expect(options.first.description).to eq("The activity was reported as eligible but was actually never ODA eligible, this applies to past and future spend")
        expect(options.last.label).to eq("No longer eligible")
        expect(options.last.description).to eq("The activity used to be ODA eligible but no longer meets the OECD DAC rules for future spend")
      end
    end

    describe "#programme_status_radio_options" do
      it "returns the BEIS codes and descriptions" do
        options = helper.programme_status_radio_options

        expect(options.length).to eq 12
        expect(options.first.value).to eq "delivery"
        expect(options.first.label).to eq "Delivery"
        expect(options.first.description).to eq "Activities related to delivery of ODA activities only"
        expect(options.last.value).to eq "paused"
        expect(options.last.label).to eq "Paused"
        expect(options.last.description).to eq "Activity has been temporarily suspended. No spend should take place while this status is in use"
      end
    end

    describe "#iati_status_from_programme_status" do
      it "returns the IATI status corresponding to the BEIS programme status" do
        %w[planned agreement_in_place open_for_applications review decided].each do |ps|
          expect(helper.iati_status_from_programme_status(ps)).to eql "1"
        end

        %w[delivery spend_in_progress].each do |ps|
          expect(helper.iati_status_from_programme_status(ps)).to eql "2"
        end

        ps = "finalisation"
        expect(helper.iati_status_from_programme_status(ps)).to eql "3"

        ps = "completed"
        expect(helper.iati_status_from_programme_status(ps)).to eql "4"

        %w[stopped cancelled].each do |ps|
          expect(helper.iati_status_from_programme_status(ps)).to eql "5"
        end

        ps = "paused"
        expect(helper.iati_status_from_programme_status(ps)).to eql "6"
      end
    end

    describe "#covid19_related_radio_options" do
      it "returns the BEIS codes and descriptions" do
        options = helper.covid19_related_radio_options

        expect(options.length).to eq 5
        expect(options.first.code).to eq 0
        expect(options.first.description).to eq "Not related"
        expect(options.last.code).to eq 4
        expect(options.last.description).to eq "Existing activity adapted to somewhat focus on COVID-19"
      end
    end

    describe "#gcrf_challenge_area_options" do
      it "returns the BEIS codes and descriptions" do
        options = helper.gcrf_challenge_area_options

        expect(options.length).to eq 13
        expect(options.first.code).to eq 0
        expect(options.first.description).to eq "Not applicable"
        expect(options.last.code).to eq 12
        expect(options.last.description).to eq "Reduce poverty and inequality, including gender inequalities"
      end
    end

    describe "#fund_pillar_radio_options" do
      it "returns the BEIS codes and descriptions" do
        options = helper.fund_pillar_radio_options

        expect(options.length).to eq 4
        expect(options.first.code).to eq 0
        expect(options.first.description).to eq "Not Applicable"
        expect(options.last.code).to eq 3
        expect(options.last.description).to eq "Translation"
      end
    end
  end
end
