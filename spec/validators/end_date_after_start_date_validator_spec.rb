require "rails_helper"

RSpec.describe EndDateAfterStartDateValidator do
  subject { build(:activity) }

  context "when the planned start date is the same as the planned end date" do
    it "is valid" do
      subject.planned_start_date = Date.today
      subject.planned_end_date = Date.today

      expect(subject.valid?).to be true
    end
  end

  context "when the planned end date is before the planned start date" do
    it "is not valid" do
      subject.planned_start_date = Date.tomorrow
      subject.planned_end_date = Date.today

      expect(subject.valid?).to be false
    end

    it "adds an error message to the :planned_end_date" do
      subject.planned_start_date = Date.tomorrow
      subject.planned_end_date = Date.today

      subject.valid?
      expect(subject.errors.messages[:planned_end_date]).to include t("activerecord.errors.models.activity.attributes.planned_end_date.not_before_start_date")
    end
  end
end
