require "rails_helper"

RSpec.describe MatchedEffort, type: :model do
  subject { build(:matched_effort) }

  describe "relations" do
    it { should belong_to(:activity) }
    it { should belong_to(:organisation) }
  end

  describe "validations" do
    it { should validate_presence_of(:organisation_id) }
    it { should validate_presence_of(:funding_type) }
    it { should validate_presence_of(:category) }
    it { should validate_presence_of(:committed_amount) }
    it { should validate_presence_of(:currency) }
    it { should validate_presence_of(:exchange_rate) }
    it { should validate_presence_of(:date_of_exchange_rate) }

    describe "organisation validations" do
      subject { build(:matched_effort, organisation: organisation) }

      context "when organisation is a matched effort provider" do
        let(:organisation) { create(:matched_effort_provider) }

        it { should be_valid }
      end

      context "when organisation is not a matched effort provider" do
        let(:organisation) { create(:delivery_partner_organisation) }

        it { should be_invalid }
      end
    end
  end
end
