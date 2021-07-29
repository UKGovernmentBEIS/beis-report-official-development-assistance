require "rails_helper"

RSpec.describe Iati::XmlDownload do
  let(:organisation) { create(:delivery_partner_organisation) }

  let(:level) { "third_party_project" }
  let(:fund) { Fund.new(2) }
  let(:fund_activity) { build(:fund_activity, :gcrf) }

  subject { described_class.new(organisation: organisation, level: level, fund: fund) }

  before do
    allow(fund).to receive(:activity).and_return(fund_activity)
  end

  describe "#path" do
    it "returns the correct path" do
      expect(subject.path).to eq("/exports/organisations/#{organisation.id}/iati/third_party_project_activities.xml?fund=#{fund.short_name}")
    end
  end

  describe "#title" do
    it "returns a title" do
      expect(subject.title).to eq("Global Challenges Research Fund IATI export for third-party project (level D) activities")
    end
  end

  describe ".all_for_organisation" do
    it "returns all XML download paths for all levels and funds in the correct order" do
      paths = described_class.all_for_organisation(organisation)

      expect(paths.count).to eq(6)

      expect(paths.map { |p| p.fund.short_name }).to eq(["NF", "GCRF", "NF", "GCRF", "NF", "GCRF"])
      expect(paths.map(&:level)).to eq(["programme", "programme", "project", "project", "third_party_project", "third_party_project"])
      expect(paths.map(&:organisation).uniq).to eq([organisation])
    end
  end
end
