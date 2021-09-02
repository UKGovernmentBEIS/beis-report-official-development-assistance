require "rails_helper"

RSpec.describe Transaction::GroupedTransactionFetcher do
  let(:report) { create(:report) }

  subject { described_class.new(report) }

  describe "#call" do
    let(:activity1) { build(:project_activity) }
    let(:activity2) { build(:project_activity) }
    let(:activity1_actuals) { build_list(:actual, 3, parent_activity: activity1) }
    let(:activity2_actuals) { build_list(:actual, 4, parent_activity: activity2) }
    let(:actuals) { activity1_actuals + activity2_actuals }
    let(:actuals_stub) { double("ActiveRecord::Relation") }

    before do
      allow(report).to receive(:actuals).and_return(actuals_stub)
      allow(actuals_stub).to receive(:includes).with([:parent_activity]).and_return(actuals)
    end

    it "returns actuals grouped by activity" do
      expect(ActivityPresenter).to receive(:new).with(activity1).exactly(3).times.and_return(activity1)
      expect(ActivityPresenter).to receive(:new).with(activity2).exactly(4).times.and_return(activity2)

      actuals.each do |actual|
        expect(TransactionPresenter).to receive(:new).with(actual).and_return(actual)
      end

      expect(subject.call).to eq({
        activity1 => activity1_actuals,
        activity2 => activity2_actuals,
      })
    end
  end
end
