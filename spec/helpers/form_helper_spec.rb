require "rails_helper"

RSpec.describe FormHelper, type: :helper do
  describe "#list_of_organisations" do
    it "asks for a sorted list of organisations" do
      expect(Organisation).to receive(:sorted_by_name)
      helper.list_of_organisations
    end
  end
end
