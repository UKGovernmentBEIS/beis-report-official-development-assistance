# frozen_string_literal: true

require "rails_helper"

RSpec.describe CodelistHelper, type: :helper do
  describe "version 2_03" do
    let(:version) { "2_03" }
    describe "#yaml_to_options" do
      it "formats the data in a yaml file to a nested array for use in options_for_select" do
        expect(helper.yaml_to_options("organisation", "default_currency")).to include(
          ["UAE Dirham", "AED"],
          ["Afghani", "AFN"],
          ["Lek", "ALL"],
          ["Armenian Dram", "AMD"],
          ["Netherlands Antillian Guilder", "ANG"],
          ["Kwanza", "AOA"]
        )
      end

      it "sorts the resulting multidimensional array in name order" do
        expect(helper.yaml_to_options("organisation", "default_currency").first).to eq(["Afghani", "AFN"])
        expect(helper.yaml_to_options("organisation", "default_currency").last).to eq(["Zloty", "PLN"])
      end
    end

    describe "#yaml_to_objects" do
      it "formats the data in a yaml file to an array of objects for use in govuk form builder" do
        expect(helper.yaml_to_objects("organisation", "default_currency")).to include(
          OpenStruct.new(name: "Afghani", code: "AFN"),
          OpenStruct.new(name: "Lek", code: "ALL"),
          OpenStruct.new(name: "Armenian Dram", code: "AMD"),
          OpenStruct.new(name: "Netherlands Antillian Guilder", code: "ANG"),
          OpenStruct.new(name: "Kwanza", code: "AOA")
        )
      end

      it "adds a blank first item by default" do
        expect(helper.yaml_to_objects("organisation", "default_currency").first).to eq(OpenStruct.new(name: "", code: ""))
      end

      it "removes the blank first item if you need it to" do
        expect(helper.yaml_to_objects("organisation", "default_currency", false).first).to_not eq(OpenStruct.new(name: "", code: ""))
      end

      it "sorts the resulting objects by name order" do
        expect(helper.yaml_to_objects("organisation", "default_currency", false).first).to eq(OpenStruct.new(name: "Afghani", code: "AFN"))
        expect(helper.yaml_to_objects("organisation", "default_currency", false).last).to eq(OpenStruct.new(name: "Zloty", code: "PLN"))
      end
    end
  end
end
