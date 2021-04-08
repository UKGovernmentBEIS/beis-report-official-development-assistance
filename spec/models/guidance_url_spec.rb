require "rails_helper"

RSpec.describe Activity::GuidanceUrl, type: :model do
  describe "#to_s" do
    it "returns a url if one exists" do
      url = GuidanceUrl.new(:activity, :programme_status)

      expect(url.to_s).to eq("https://beisodahelp.zendesk.com/hc/en-gb/articles/1500005354781")
    end

    it "returns nil if does not exist" do
      url = GuidanceUrl.new(:foo, :bar)

      expect(url.to_s).to eq("")
    end
  end
end
