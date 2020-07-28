require "rails_helper"

RSpec.describe Submission, type: :model do
  describe "validations" do
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:state) }
  end

  describe "associations" do
    it { should belong_to(:fund).class_name("Activity") }
    it { should belong_to(:organisation) }
  end

  it "does not allow an association to an Activity that is not level = fund" do
    programme = create(:programme_activity)
    submission = build(:submission, fund: programme)
    expect(submission).not_to be_valid
    expect(submission.errors[:fund]).to include I18n.t("activerecord.errors.models.submission.attributes.fund.level")
  end

  it "does not allow more than one Submission for the same Fund and Organisation combination" do
    organisation = create(:delivery_partner_organisation)
    fund = create(:fund_activity)
    _existing_submission = create(:submission, organisation: organisation, fund: fund)

    new_submission = build(:submission, organisation: organisation, fund: fund)
    expect(new_submission).not_to be_valid
  end

  it "does not allow a Deadline which is in the past" do
    submission = build(:submission, deadline: Date.yesterday)
    expect(submission).not_to be_valid
  end
end
