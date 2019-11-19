# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserHelper, type: :helper do
  describe "#organisation_check_box_options" do
    it "returns an array of all organisations" do
      first_organisation = create(:organisation)
      second_organisation = create(:organisation)

      expect(helper.organisation_check_box_options)
        .to match([
          [first_organisation.name, first_organisation.id],
          [second_organisation.name, second_organisation.id],
        ])
    end
  end
end
