require "rails_helper"

RSpec.describe MatchedEffort, type: :model do
  subject { build(:matched_effort) }

  describe "relations" do
    it { should belong_to(:activity) }
    it { should belong_to(:organisation) }
  end
end
