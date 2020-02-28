require "rails_helper"

RSpec.describe BudgetDatesValidator do
  subject { build(:budget) }

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
      expect(subject.errors.messages[:period_start_date]).to include I18n.t("activerecord.errors.models.budget.attributes.period_start_date.not_after_end_date")
    end
  end

  context "when the dates are within 365 days of each other" do
    it "is valid" do
      subject.period_start_date = Date.today
      subject.period_end_date = subject.period_start_date + 6.months

      expect(subject).to be_valid
    end
  end

  context "when the dates are exactly 365 days apart from each other" do
    it "is valid" do
      subject.period_start_date = Date.today
      subject.period_end_date = subject.period_start_date + 365.days

      expect(subject).to be_valid
    end
  end

  context "when the dates are more than 365 days apart" do
    it "is invalid" do
      subject.period_start_date = Date.today
      subject.period_end_date = subject.period_start_date + 366.days

      expect(subject).not_to be_valid
    end

    it "adds an error message to the :period_end_date" do
      subject.period_start_date = Date.today
      subject.period_end_date = subject.period_start_date + 366.days

      subject.valid?
      expect(subject.errors.messages[:period_end_date]).to include I18n.t("activerecord.errors.models.budget.attributes.period_end_date.within_365_days_of_start_date")
    end
  end
end
