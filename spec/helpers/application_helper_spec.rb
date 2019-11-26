# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#l" do
    it "allows nil to be passed to `localize` without blowing up" do
      expect(helper.l(nil)).to eq(nil)
    end

    it "localises dates as expected" do
      expect(helper.l(Date.today)).to eq(Date.today.strftime("%Y-%m-%d"))
    end
  end
end
