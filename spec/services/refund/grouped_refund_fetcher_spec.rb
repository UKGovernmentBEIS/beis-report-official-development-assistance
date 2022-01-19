require "rails_helper"

RSpec.describe Refund::GroupedRefundFetcher do
  let(:report) { create(:report) }

  subject { described_class.new(report) }

  describe "#call" do
    let(:activity1) { build(:project_activity) }
    let(:activity2) { build(:project_activity) }
    let(:activity1_refunds) { build_list(:refund, 4, parent_activity: activity1) }
    let(:activity2_refunds) { build_list(:refund, 3, parent_activity: activity2) }
    let(:refunds) { activity1_refunds + activity2_refunds }
    let(:refunds_stub) { double("ActiveRecord::Relation") }

    before do
      allow(report).to receive(:refunds).and_return(refunds_stub)
      allow(refunds_stub).to receive(:includes).with([:parent_activity]).and_return(refunds)
    end

    it "returns refunds grouped by activity" do
      expect(ActivityPresenter).to receive(:new).with(activity1).exactly(4).times.and_return(activity1)
      expect(ActivityPresenter).to receive(:new).with(activity2).exactly(3).times.and_return(activity2)

      refunds.each do |refund|
        expect(RefundPresenter).to receive(:new).with(refund).and_return(refund)
      end

      expect(subject.call).to eq({
        activity1 => activity1_refunds,
        activity2 => activity2_refunds
      })
    end
  end
end
