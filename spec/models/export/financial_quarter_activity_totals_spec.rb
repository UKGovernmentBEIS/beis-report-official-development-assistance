RSpec.describe Export::FinancialQuarterActivityTotals do
  let(:totals) {
    {
      [activity.id, 1, 2020, "Refund", nil] => 200,
      [activity.id, 1, 2020, "Actual", nil] => 300,
      [activity.id, 1, 2020, "Adjustment", "Actual"] => -100,
      [activity.id, 1, 2020, "Adjustment", "Refund"] => -50
    }
  }

  let(:activity) { build(:project_activity) }
  let(:financial_quarter) { FinancialQuarter.new(2020, 1) }

  subject { described_class.new(type: type, activity: activity, totals: totals, financial_quarter: financial_quarter) }

  context "when the type is `:actual`" do
    let(:type) { :actual }

    describe "#net_total" do
      it "returns the total actual spend plus any adjustments" do
        expect(subject.net_total).to eq(200)
      end
    end

    describe "#total" do
      it "returns only the total actual spend" do
        expect(subject.total).to eq(300)
      end
    end

    describe "#adjustment_total" do
      it "returns only the total actual spend adjustments" do
        expect(subject.adjustments_total).to eq(-100)
      end
    end
  end

  context "when the type is `:refund`" do
    let(:type) { :refund }

    describe "#net_total" do
      it "returns the total refunds plus any adjustments" do
        expect(subject.net_total).to eql(150)
      end
    end

    describe "#total" do
      it "returns the total refunds" do
        expect(subject.total).to eq(200)
      end
    end

    describe "#adjustment_total" do
      it "returns the total refund spend adjustments" do
        expect(subject.adjustments_total).to eq(-50)
      end
    end
  end
end
