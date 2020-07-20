# frozen_string_literal: true

require "rails_helper"

RSpec.describe SubmissionPresenter do
  describe "#state" do
    it "returns the string for the state" do
      submission = build(:submission, state: "inactive")
      result = described_class.new(submission).state
      expect(result).to eql("Inactive")
    end
  end
end
