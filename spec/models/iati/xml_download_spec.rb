require "rails_helper"

RSpec.describe Iati::XmlDownload do
  let(:organisation) { create(:partner_organisation) }

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
    let(:programme_relation) { double("ActiveRecord::Relation", where: []) }
    let(:project_relation) { double("ActiveRecord::Relation", where: []) }
    let(:third_party_project_relation) { double("ActiveRecord::Relation", where: []) }

    before do
      allow(Activity).to receive(:programme).and_return(programme_relation)
      allow(Activity).to receive(:project).and_return(project_relation)
      allow(Activity).to receive(:third_party_project).and_return(third_party_project_relation)
    end

    context "when the organisation has publishable activities for each level and fund" do
      before do
        allow(Iati::XmlDownload).to receive(:organisation_has_activities_for_level_and_fund?).and_return(true)
      end

      it "returns all XML downloads ordered by levels, then funds" do
        downloads = described_class.all_for_organisation(organisation)

        expect(downloads.count).to eq(12)

        expect(downloads.map { |download| download.fund.short_name }).to eq(%w[
          NF GCRF OODA ISPF
          NF GCRF OODA ISPF
          NF GCRF OODA ISPF
        ])

        expect(downloads.map(&:level)).to eq(%w[
          programme programme programme programme
          project project project project
          third_party_project third_party_project third_party_project third_party_project
        ])
        expect(downloads.map(&:organisation).uniq).to eq([organisation])
      end

      context "and the feature flag hiding ISPF is enabled" do
        before do
          mock_feature = double(:feature, groups: [:beis_users])
          allow(ROLLOUT).to receive(:get).and_return(mock_feature)
        end

        it "does not return XML downloads for ISPF" do
          downloads = described_class.all_for_organisation(organisation)

          expect(downloads.count).to eq(9)

          expect(downloads.map { |p| p.fund.short_name }).to eq(%w[
            NF GCRF OODA
            NF GCRF OODA
            NF GCRF OODA
          ])
        end
      end
    end

    context "when the organisation has publishable activities for some levels and funds" do
      before do
        allow(Iati::XmlDownload).to receive(:organisation_has_activities_for_level_and_fund?).and_return(false)

        [
          {level: "project", fund_short_name: "NF"},
          {level: "project", fund_short_name: "GCRF"},
          {level: "third_party_project", fund_short_name: "GCRF"}
        ].each do |combination|
          allow(Iati::XmlDownload).to receive(:organisation_has_activities_for_level_and_fund?).with(
            organisation,
            combination[:level],
            Fund.by_short_name(combination[:fund_short_name])
          ).and_return(true)
        end
      end

      it "only returns XML download paths for levels and funds that have publishable activities" do
        paths = described_class.all_for_organisation(organisation)

        expect(paths.count).to eq(3)

        expect(paths.map { |p| p.fund.short_name }).to eq(["NF", "GCRF", "GCRF"])
        expect(paths.map(&:level)).to eq(["project", "project", "third_party_project"])
        expect(paths.map(&:organisation).uniq).to eq([organisation])
      end
    end
  end
end
