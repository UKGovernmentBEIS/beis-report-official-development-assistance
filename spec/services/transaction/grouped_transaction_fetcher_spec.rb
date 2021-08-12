require "rails_helper"

RSpec.describe Transaction::GroupedTransactionFetcher do
  let(:report) { create(:report) }

  subject { described_class.new(report) }

  describe "#call" do
    let(:activity1) { build(:project_activity) }
    let(:activity2) { build(:project_activity) }
    let(:activity1_transactions) { build_list(:transaction, 3, parent_activity: activity1) }
    let(:activity2_transactions) { build_list(:transaction, 4, parent_activity: activity2) }
    let(:transactions) { activity1_transactions + activity2_transactions }
    let(:transactions_stub) { double("ActiveRecord::Relation") }

    before do
      allow(report).to receive(:transactions).and_return(transactions_stub)
      allow(transactions_stub).to receive(:includes).with([:parent_activity]).and_return(transactions)
    end

    it "returns transactions grouped by activity" do
      expect(ActivityPresenter).to receive(:new).with(activity1).exactly(3).times.and_return(activity1)
      expect(ActivityPresenter).to receive(:new).with(activity2).exactly(4).times.and_return(activity2)

      transactions.each do |transaction|
        expect(TransactionPresenter).to receive(:new).with(transaction).and_return(transaction)
      end

      expect(subject.call).to eq({
        activity1 => activity1_transactions,
        activity2 => activity2_transactions,
      })
    end
  end
end
