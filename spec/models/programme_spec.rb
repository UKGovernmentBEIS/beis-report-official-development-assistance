require "rails_helper"

RSpec.describe Programme do
  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe "relations" do
    it { is_expected.to belong_to(:organisation) }
    it { is_expected.to belong_to(:fund) }
  end
end
