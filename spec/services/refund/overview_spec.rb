RSpec.describe Refund::Overview do
  let(:delivery_partner) { create(:delivery_partner_organisation) }
  let(:project) { create(:project_activity, organisation: delivery_partner) }
  let(:reporting_cycle) { ReportingCycle.new(project, 4, 2018) }
  let(:include_adjustments) { false }
  let(:overview) { described_class.new(report: report, include_adjustments: include_adjustments) }

  #   Report:     2018-Q4     2019-Q1     2019-Q2
  #   Quarter
  #   -------------------------------------------
  #   2017-Q1         -5
  #   2017-Q2                    -800
  #   2017-Q3                              -4,000
  #   2017-Q4         -10         -40
  #   2018-Q1         -30                    -900
  #   2018-Q2                  -1,000        -480
  #   2018-Q3         -10         -60        -910
  #   2018-Q4        -120                    -810

  before do
    reporting_cycle.tick
    create_refund(financial_year: 2017, financial_quarter: 1, value: 5)
    create_refund(financial_year: 2017, financial_quarter: 4, value: 10)
    create_refund(financial_year: 2018, financial_quarter: 1, value: 30)
    create_refund(financial_year: 2018, financial_quarter: 3, value: 10)
    create_refund(financial_year: 2018, financial_quarter: 4, value: 120)

    create_adjustment(financial_year: 2017, financial_quarter: 4, value: 20, adjustment_type: :refund)

    reporting_cycle.tick
    create_refund(financial_year: 2017, financial_quarter: 2, value: 800)
    create_refund(financial_year: 2017, financial_quarter: 4, value: 40)
    create_refund(financial_year: 2018, financial_quarter: 2, value: 1_000)
    create_refund(financial_year: 2018, financial_quarter: 3, value: 60)

    create_adjustment(financial_year: 2017, financial_quarter: 2, value: 70, adjustment_type: :refund)

    reporting_cycle.tick
    create_refund(financial_year: 2017, financial_quarter: 3, value: 4_000)
    create_refund(financial_year: 2018, financial_quarter: 1, value: 900)
    create_refund(financial_year: 2018, financial_quarter: 2, value: 480)
    create_refund(financial_year: 2018, financial_quarter: 3, value: 910)
    create_refund(financial_year: 2018, financial_quarter: 4, value: 810)

    create_adjustment(financial_year: 2017, financial_quarter: 3, value: 40, adjustment_type: :refund)
  end

  context "for the first report" do
    let(:report) { Report.for_activity(project).find_by(financial_quarter: 4, financial_year: 2018) }

    let(:expected_values) {
      [
        [1, 2017, -5],
        [2, 2017, 0],
        [3, 2017, 0],
        [4, 2017, -10],
        [1, 2018, -30],
        [2, 2018, 0],
        [3, 2018, -10],
        [4, 2018, -120],
      ]
    }

    it_should_behave_like "transaction report history"

    context "when adjustments are included" do
      let(:include_adjustments) { true }
      let(:expected_values) {
        [
          [1, 2017, -5],
          [2, 2017, 0],
          [3, 2017, 0],
          [4, 2017, 10],
          [1, 2018, -30],
          [2, 2018, 0],
          [3, 2018, -10],
          [4, 2018, -120],
        ]
      }

      it_should_behave_like "transaction report history"
    end
  end

  context "for the middle report" do
    let(:report) { Report.for_activity(project).find_by(financial_quarter: 1, financial_year: 2019) }

    let(:expected_values) {
      [
        [1, 2017, -5],
        [2, 2017, -800],
        [3, 2017, 0],
        [4, 2017, -50],
        [1, 2018, -30],
        [2, 2018, -1_000],
        [3, 2018, -70],
        [4, 2018, -120],
      ]
    }

    it_should_behave_like "transaction report history"

    context "when adjustments are included" do
      let(:include_adjustments) { true }
      let(:expected_values) {
        [
          [1, 2017, -5],
          [2, 2017, -730],
          [3, 2017, 0],
          [4, 2017, -30],
          [1, 2018, -30],
          [2, 2018, -1_000],
          [3, 2018, -70],
          [4, 2018, -120],
        ]
      }

      it_should_behave_like "transaction report history"
    end
  end

  context "for the latest report" do
    let(:report) { Report.for_activity(project).find_by(financial_quarter: 2, financial_year: 2019) }

    let(:expected_values) {
      [
        [1, 2017, -5],
        [2, 2017, -800],
        [3, 2017, -4000],
        [4, 2017, -50],
        [1, 2018, -930],
        [2, 2018, -1_480],
        [3, 2018, -980],
        [4, 2018, -930],
      ]
    }

    it_should_behave_like "transaction report history"

    context "when adjustments are included" do
      let(:include_adjustments) { true }
      let(:expected_values) {
        [
          [1, 2017, -5],
          [2, 2017, -730],
          [3, 2017, -3960],
          [4, 2017, -30],
          [1, 2018, -930],
          [2, 2018, -1_480],
          [3, 2018, -980],
          [4, 2018, -930],
        ]
      }

      it_should_behave_like "transaction report history"
    end
  end
end
