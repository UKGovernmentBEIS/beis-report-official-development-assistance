require "rails_helper"

RSpec.describe DateNotInPastValidator do
  subject do
    Class.new {
      include ActiveModel::Validations
      attr_accessor :deadline
      validates :deadline, date_not_in_past: true

      def self.name
        "Submission"
      end
    }.new
  end

  describe "#valid?" do
    context "when date is nil" do
      it "is valid" do
        subject.deadline = nil
        expect(subject.valid?).to be true
      end
    end

    context "when date is today" do
      it "is not valid" do
        travel_to Time.zone.local(2004, 11, 24)

        subject.deadline = Date.new(2004, 11, 24)
        expect(subject.valid?).to be false

        travel_back
      end
    end

    context "when date is in the future" do
      it "is valid" do
        travel_to Time.zone.local(2004, 11, 24)

        subject.deadline = Date.new(2005, 1, 1)
        expect(subject.valid?).to be true

        travel_back
      end
    end

    context "when date is in the past" do
      it "is not valid" do
        travel_to Time.zone.local(2004, 11, 24)

        subject.deadline = Date.new(2003, 1, 1)
        expect(subject.valid?).to be false

        travel_back
      end
    end
  end
end
