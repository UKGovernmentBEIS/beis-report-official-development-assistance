require "rails_helper"

RSpec.describe Report, type: :model do
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
    report = build(:report, fund: programme)
    expect(report).not_to be_valid
    expect(report.errors[:fund]).to include I18n.t("activerecord.errors.models.report.attributes.fund.level")
  end

  it "does not allow more than one Report for the same Fund and Organisation combination" do
    organisation = create(:delivery_partner_organisation)
    fund = create(:fund_activity)
    _existing_report = create(:report, organisation: organisation, fund: fund)

    new_report = build(:report, organisation: organisation, fund: fund)
    expect(new_report).not_to be_valid
  end

  it "does not allow a Deadline which is in the past" do
    report = build(:report, deadline: Date.yesterday)
    expect(report).not_to be_valid
  end
end
