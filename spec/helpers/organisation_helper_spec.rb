# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrganisationHelper, type: :helper do
  describe "#yaml_to_options" do
    it "formats the data in a yaml file to a nested array for use in options_for_select" do
      yaml_snippet = YAML.safe_load(File.read("spec/fixtures/default_currency.yml"))
      allow(helper).to receive(:load_yaml).and_return(yaml_snippet)

      expect(helper.yaml_to_options("default_currency")).to eq [
        ["UAE Dirham", "AED"],
        ["Afghani", "AFN"],
        ["Lek", "ALL"],
        ["Armenian Dram", "AMD"],
        ["Netherlands Antillian Guilder", "ANG"],
      ]
    end
  end
end
