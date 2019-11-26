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
    end
  end
end
