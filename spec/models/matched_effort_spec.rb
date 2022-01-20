require "rails_helper"

RSpec.describe MatchedEffort, type: :model do
  let(:organisation) { create(:matched_effort_provider) }

  subject { build(:matched_effort, organisation: organisation) }

  describe "relations" do
    it { should belong_to(:activity) }
    it { should belong_to(:organisation) }
  end

  describe "validations" do
    it { should validate_presence_of(:organisation_id) }
    it { should validate_presence_of(:funding_type) }

    describe "organisation validations" do
      context "when organisation is a matched effort provider" do
        it { should be_valid }
      end

      context "when organisation is not a matched effort provider" do
        let(:organisation) { create(:delivery_partner_organisation) }

        it { should be_invalid }
      end
    end

    describe "category validations" do
      subject { build(:matched_effort, funding_type: funding_type, category: category, organisation: organisation) }
      let(:category) { nil }

      context "when the funding type is in kind" do
        let(:funding_type) { "in_kind" }

        it { should validate_presence_of(:category) }

        context "and the category is not applicable to the in kind funding type" do
          let(:category) { "fellowship" }

          it { should be_invalid }
        end

        [
          "staff_time",
          "workshops",
          "training",
          "access_to_data",
          "use_of_facilities",
          "unspecified"
        ].each do |category|
          context "and the category is `#{category}`" do
            let(:category) { category }

            it { should be_valid }
          end
        end
      end

      context "when the funding type is reciprocal" do
        let(:category) { "fellowship" }
        let(:funding_type) { "reciprocal" }

        it { should validate_presence_of(:category) }

        context "and the category is not applicable to the reciprocal funding type" do
          let(:category) { "staff_time" }

          it { should be_invalid }
        end

        [
          "fellowship",
          "other"
        ].each do |category|
          context "and the category is `#{category}`" do
            let(:category) { category }

            it { should be_valid }
          end
        end
      end

      context "when the funding type is co-funding" do
        let(:funding_type) { "co-funding" }

        it { should_not validate_presence_of(:category) }
      end

      context "when the funding type is direct" do
        let(:funding_type) { "direct" }

        it { should_not validate_presence_of(:category) }
      end
    end
  end
end
