RSpec.describe PlannedDisbursementOverview do
  let(:overview) { PlannedDisbursementOverview.new(activity) }
  let(:histories) { {} }

  def forecast_values(records)
    records.map do |entry|
      [entry.financial_quarter, entry.financial_year, entry.value]
    end
  end

  before do
    [2017, 2018].each do |year|
      (1..4).each do |quarter|
        history = PlannedDisbursementHistory.new(activity, financial_quarter: quarter, financial_year: year)
        histories[[year, quarter]] = history
      end
    end
  end

  context "for a level B activity, with no persistent history" do
    let(:beis) { create(:beis_organisation) }
    let(:activity) { create(:programme_activity, organisation: beis) }

    before do
      histories[[2017, 1]].set_value(10)
      histories[[2017, 2]].set_value(20)
      histories[[2017, 3]].set_value(30)
      histories[[2017, 3]].set_value(40)
    end

    it "returns the latest values of all forecasts for an activity" do
      forecasts = forecast_values(overview.latest_values)

      expect(forecasts).to eq([
        [1, 2017, 10],
        [2, 2017, 20],
        [3, 2017, 40],
      ])
    end

    it "does not support requesting values at a specific report" do
      expect { overview.snapshot(Report.new).all_quarters }.to raise_error(TypeError)
    end

    context "when a forecast has been deleted" do
      before do
        histories[[2017, 2]].clear
      end

      it "omits that forecast from the result set" do
        forecasts = forecast_values(overview.latest_values)

        expect(forecasts).to eq([
          [1, 2017, 10],
          [3, 2017, 40],
        ])
      end
    end
  end

  context "for a level C activity, with report-pinned history" do
    let(:delivery_partner) { create(:delivery_partner_organisation) }
    let(:activity) { create(:project_activity, organisation: delivery_partner) }
    let(:reporting_cycle) { ReportingCycle.new(activity, 4, 2015) }

    #   Report:     2015-Q4     2016-Q1     2016-Q2
    #   Quarter
    #   -------------------------------------------
    #   2017-Q1          10
    #   2017-Q2                      60
    #   2017-Q3                                 100
    #   2017-Q4          20          70
    #   2018-Q1          30                     110
    #   2018-Q2                      80         120
    #   2018-Q3          40           0         130
    #   2018-Q4          50                     140

    before do
      reporting_cycle.tick
      histories[[2017, 1]].set_value(10)
      histories[[2017, 4]].set_value(20)
      histories[[2018, 1]].set_value(30)
      histories[[2018, 3]].set_value(40)
      histories[[2018, 4]].set_value(50)

      reporting_cycle.tick
      histories[[2017, 2]].set_value(60)
      histories[[2017, 4]].set_value(70)
      histories[[2018, 2]].set_value(80)
      histories[[2018, 3]].set_value(0)

      reporting_cycle.tick
      histories[[2017, 3]].set_value(100)
      histories[[2018, 1]].set_value(110)
      histories[[2018, 2]].set_value(120)
      histories[[2018, 3]].set_value(130)
      histories[[2018, 4]].set_value(140)
    end

    it "returns the latest values of all forecasts for an activity" do
      forecasts = forecast_values(overview.latest_values)

      expect(forecasts).to eq([
        [1, 2017, 10],
        [2, 2017, 60],
        [3, 2017, 100],
        [4, 2017, 70],
        [1, 2018, 110],
        [2, 2018, 120],
        [3, 2018, 130],
        [4, 2018, 140],
      ])
    end

    context "when a forecast has been deleted" do
      before do
        histories[[2018, 4]].clear
      end

      it "omits that forecast from the result set" do
        forecasts = forecast_values(overview.latest_values)

        expect(forecasts).to eq([
          [1, 2017, 10],
          [2, 2017, 60],
          [3, 2017, 100],
          [4, 2017, 70],
          [1, 2018, 110],
          [2, 2018, 120],
          [3, 2018, 130],
        ])
      end
    end

    shared_examples_for "forecast report history" do
      it "returns the forecast values for all quarters" do
        forecasts = forecast_values(overview.snapshot(report).all_quarters.as_records)
        expect(forecasts).to eq(expected_values)
      end

      it "returns the forecast value for a particular quarter" do
        expected_values.each do |quarter, year, amount|
          value = overview.snapshot(report).all_quarters.value_for(financial_quarter: quarter, financial_year: year)
          expect(value).to eq(amount)
        end
      end
    end

    context "for the first report" do
      let(:report) { Report.for_activity(activity).find_by(financial_quarter: 4, financial_year: 2015) }

      let(:expected_values) {
        [
          [1, 2017, 10],
          [4, 2017, 20],
          [1, 2018, 30],
          [3, 2018, 40],
          [4, 2018, 50],
        ]
      }

      it_should_behave_like "forecast report history"
    end

    context "for a specific report" do
      let(:report) { Report.for_activity(activity).find_by(financial_quarter: 1, financial_year: 2016) }

      let(:expected_values) {
        [
          [1, 2017, 10],
          [2, 2017, 60],
          [4, 2017, 70],
          [1, 2018, 30],
          [2, 2018, 80],
          [4, 2018, 50],
        ]
      }

      it_should_behave_like "forecast report history"

      it "returns zero for the value of a quarter that was revised to zero in that report" do
        value = overview.snapshot(report).all_quarters.value_for(financial_quarter: 3, financial_year: 2018)
        expect(value).to eq(0)
      end
    end

    it "can return the forecast value for the quarter of a report" do
      6.times { reporting_cycle.tick }

      expected_values = [
        [1, 2017, 10],
        [2, 2017, 60],
        [3, 2017, 100],
        [4, 2017, 70],
      ]

      expected_values.each do |quarter, year, amount|
        report = Report.for_activity(activity).find_by(financial_year: year, financial_quarter: quarter)
        expect(overview.snapshot(report).value_for_report_quarter).to eq(amount)
      end
    end

    it "returns a zero forecast value for a report whose quarter has no forecast" do
      report = Report.for_activity(activity).find_by(financial_year: 2016, financial_quarter: 2)
      expect(overview.snapshot(report).value_for_report_quarter).to eq(0)
    end

    context "when the first report is a historic one with no financial quarter" do
      let(:report) { Report.for_activity(activity).find_by(financial_quarter: 4, financial_year: 2015) }

      let(:expected_values) {
        [
          [1, 2017, 10],
          [4, 2017, 20],
          [1, 2018, 30],
          [3, 2018, 40],
          [4, 2018, 50],
        ]
      }

      before do
        Report.where(id: report.id).update_all(financial_quarter: nil, financial_year: nil)
      end

      it_should_behave_like "forecast report history"
    end

    context "when there are two reports for the same financial quarter" do
      let(:reports) { Report.in_historical_order.to_a }

      before do
        Report.where(id: reports.first.id).update_all(financial_quarter: 1)
        quarters = Report.in_historical_order.map { |r| [r.financial_quarter, r.financial_year] }

        expect(quarters).to eq([
          [1, 2016],
          [1, 2016],
          [4, 2015],
        ])
      end

      it "returns the latest values of all forecasts for an activity" do
        forecasts = forecast_values(overview.latest_values)

        expect(forecasts).to eq([
          [1, 2017, 10],
          [2, 2017, 60],
          [3, 2017, 100],
          [4, 2017, 70],
          [1, 2018, 110],
          [2, 2018, 120],
          [3, 2018, 130],
          [4, 2018, 140],
        ])
      end

      context "for the latest report" do
        let(:report) { reports[0] }

        let(:expected_values) {
          [
            [1, 2017, 10],
            [2, 2017, 60],
            [3, 2017, 100],
            [4, 2017, 70],
            [1, 2018, 110],
            [2, 2018, 120],
            [3, 2018, 130],
            [4, 2018, 140],
          ]
        }

        it_should_behave_like "forecast report history"
      end

      context "for the penultimate report" do
        let(:report) { reports[1] }

        let(:expected_values) {
          [
            [1, 2017, 10],
            [2, 2017, 60],
            [4, 2017, 70],
            [1, 2018, 30],
            [2, 2018, 80],
            [4, 2018, 50],
          ]
        }

        it_should_behave_like "forecast report history"
      end
    end

    context "when there are forecasts for multiple activities" do
      let(:project) { create(:project_activity, parent: activity.parent, organisation: delivery_partner) }
      let(:project_history) { PlannedDisbursementHistory.new(project, financial_quarter: 1, financial_year: 2019) }
      let(:project_overview) { PlannedDisbursementOverview.new(project) }

      before do
        reporting_cycle.tick
        project_history.set_value(200)
      end

      it "only includes forecasts for the given activity" do
        expect(forecast_values(project_overview.latest_values)).to eq([
          [1, 2019, 200],
        ])

        expect(overview.latest_values).to all(satisfy { |forecast|
          forecast.parent_activity == activity
        })
      end
    end
  end
end
