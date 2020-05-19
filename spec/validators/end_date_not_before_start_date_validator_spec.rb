require "rails_helper"

RSpec.describe EndDateNotBeforeStartDateValidator do
  subject { create(:planned_disbursement) }

  context "when the start date is the same as the end date" do
    it "is valid" do
      subject.period_start_date = Date.today
      subject.period_end_date = Date.today

      expect(subject).to be_valid
    end
  end

  context "when the start date is before the end date" do
    it "is valid" do
      subject.period_start_date = Date.yesterday
      subject.period_end_date = Date.today

      expect(subject).to be_valid
    end
  end

  context "when the start date is after the end date" do
    it "is not valid" do
      subject.period_start_date = Date.tomorrow
      subject.period_end_date = Date.today

      expect(subject).not_to be_valid
    end

    it "adds an error message to the :period_start_date" do
      subject.period_start_date = Date.tomorrow
      subject.period_end_date = Date.today

      subject.valid?
      expect(subject.errors.messages[:period_end_date]).to include I18n.t("activerecord.errors.validators.end_date_not_before_start_date")
    end
  end
end
