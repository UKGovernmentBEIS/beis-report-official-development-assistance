require "rails_helper"

RSpec.describe MatchedEffortCategoryValidator do
  subject { build(:matched_effort, organisation: create(:matched_effort_provider)) }

  context "when the category is applicable to the funding type" do
    it "is valid" do
      subject.funding_type = "in_kind"
      subject.category = "staff_time"

      expect(subject).to be_valid
    end
  end

  context "when the category is not applicable to the funding type" do
    before do
      subject.funding_type = "in_kind"
      subject.category = "fellowship"
    end

    it "is invalid" do
      expect(subject).to_not be_valid
    end

    it "adds an error message" do
      subject.valid?
      expect(subject.errors.full_messages).to include("Category 'Fellowship' is not valid for the funding type 'In kind'")
    end

    it "sets the category to nil" do
      subject.valid?
      expect(subject.category).to be_nil
    end
  end
end
