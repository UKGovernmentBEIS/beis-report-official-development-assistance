require "rails_helper"
require "legacy_activity"

RSpec.describe LegacyActivity do
  let(:activity_node_set) do
    Nokogiri::XML(
      File.read("#{Rails.root}/spec/fixtures/activities/uksa/single_activity.xml"),
      nil,
      "UTF-8"
    ).xpath("//iati-activity").first
  end

  describe "#elements" do
    it "returns the nokogiri nodes for this document" do
      result = described_class.new(activity_node_set: activity_node_set).elements
      expect(result.class).to eql(Nokogiri::XML::NodeSet)
    end
  end

  describe "#to_xml" do
    it "returns the xml representation for this document" do
      legacy_xml = File.read("#{Rails.root}/spec/fixtures/activities/uksa/individual_activity.xml")

      result = described_class.new(activity_node_set: activity_node_set).to_xml

      expect(result.squish).to eql(legacy_xml.squish)
    end
  end
end
