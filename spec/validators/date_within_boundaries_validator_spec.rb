require "rails_helper"

RSpec.describe DateWithinBoundariesValidator do
  subject do
    Class.new {
      include ActiveModel::Validations
      attr_accessor :date
      validates :date, date_within_boundaries: true

      def self.name
        "Transaction"
      end
    }.new
  end

  describe "when date is nil" do
    it "is valid" do
      subject.date = nil
      expect(subject.valid?).to be true
    end
  end

  describe "when date is within range" do
    it "is valid" do
      subject.date = Date.today
      expect(subject.valid?).to be true
    end
  end

  # Temporarily suspended as BEIS are inputting historical activities with a longer-ago start date
  describe "when date is more than 10 years ago" do
    xit "is not valid" do
      subject.date = 11.years.ago
      expect(subject.valid?).to be false
    end
  end

  # TODO: Remove this test when historical activities migration is complete
  # The earliest date BEIS have provided is 2005 (17 years ago)
  describe "when date is more than 17 years ago" do
    it "is not valid" do
      subject.date = 18.years.ago
      expect(subject.valid?).to be false
    end
  end

  describe "when date is more than 25 years in the future" do
    it "is not valid" do
      subject.date = 26.years.from_now
      expect(subject.valid?).to be false
    end
  end
end
