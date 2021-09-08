require "spec_helper"

RSpec.describe BenefittingCountry do
  describe ".all" do
    subject { described_class.all }

    it "returns all the countries" do
      expect(subject.count).to eq(177)
    end
  end
end
