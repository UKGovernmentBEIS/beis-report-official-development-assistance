# frozen_string_literal: true

require "rails_helper"

RSpec.describe CodelistHelper, type: :helper do
  describe "version 2_03" do
    let(:version) { "2_03" }
    describe "#yaml_to_objects" do
      it "gracefully handles a missing or incorrect yaml file" do
        expect(helper.yaml_to_objects(entity: "generic", type: "favourite_colours")).to eq([])
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
      it "gracefully handles a missing or incorrect yaml file" do
        expect(helper.yaml_to_objects_with_description(entity: "generic", type: "favourite_colours")).to eq([])
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
          type: "status",
        ).last).to eq(OpenStruct.new(name: "Suspended", code: "6", description: "The activity has been temporarily suspended"))
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

    describe "#country_select_options" do
      it "returns an array of country objects with '' as the first (default) option" do
        expect(helper.country_select_options.first)
          .to eq(OpenStruct.new(name: I18n.t("page_content.activity.recipient_country.default_selection_value"), code: ""))
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

        expect(options.length).to eq 283
        expect(options).to include OpenStruct.new(name: "Women's equality organisations and institutions", code: "15170", category: "151")
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
  end
end
