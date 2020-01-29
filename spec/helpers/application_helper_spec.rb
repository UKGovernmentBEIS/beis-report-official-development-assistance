# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#l" do
    it "allows nil to be passed to `localize` without blowing up" do
      expect(helper.l(nil)).to eq(nil)
    end

    it "localises dates as expected" do
      expect(helper.l(Date.today)).to eq(Date.today.strftime("%-d %b %Y"))
    end
  end

  describe "#navigation_item_class" do
    let(:subject) { helper.navigation_item_class("some_path") }

    before do
      allow(helper).to receive(:current_page?).and_return true
    end

    it "returns the active navigation item class" do
      expect(subject).to eql "govuk-header__navigation-item govuk-header__navigation-item--active"
    end
  end
end
