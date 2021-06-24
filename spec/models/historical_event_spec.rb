require "rails_helper"

RSpec.describe HistoricalEvent, type: :model do
  describe "associations" do
    it { should belong_to(:activity) }
    it { should belong_to(:user) }
  end
end
