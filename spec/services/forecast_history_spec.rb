RSpec.describe ForecastHistory do
  let(:edited_report) { nil }
  let(:user) { create(:delivery_partner_user) }
  let(:history) { ForecastHistory.new(activity, financial_quarter: 3, financial_year: 2020, report: edited_report, user: user) }
  let(:reporting_cycle) { ReportingCycle.new(activity, 1, 2015) }

  def history_entries
    history.all_entries.map do |entry|
      [
        entry.forecast_type,
        entry.report&.financial_quarter,
        entry.report&.financial_year,
        entry.value
      ]
    end
  end

  context "for a level B activity, owned by BEIS" do
    let(:beis) { create(:beis_organisation) }
    let(:activity) { create(:programme_activity, organisation: beis) }

    it "begins with no entries" do
      expect(history_entries).to eq([])
    end

    it "creates an original entry when the value is first set" do
      history.set_value(10)

      expect(history_entries).to eq([
        ["original", nil, nil, 10]
      ])
    end

    it "does not create a historical event when the value is first set" do
      expect { history.set_value(10) }.to not_create_a_historical_event
    end

    it "creates an original with a negative value" do
      history.set_value(-10)

      expect(history_entries).to eq([
        ["original", nil, nil, -10]
      ])
    end

    it "does not create an original entry with a zero value" do
      history.set_value(0)
      expect(history_entries).to eq([])
    end

    it "adds a revision when the value is first updated" do
      history.set_value(10)
      history.set_value(20)

      expect(history_entries).to eq([
        ["original", nil, nil, 10],
        ["revised", nil, nil, 20]
      ])
    end

    it "does not create a historical event when the value is first updated" do
      history.set_value(10)

      expect { history.set_value(20) }.to not_create_a_historical_event
    end

    it "adds a revision with a zero value" do
      history.set_value(10)
      history.set_value(0)

      expect(history_entries).to eq([
        ["original", nil, nil, 10],
        ["revised", nil, nil, 0]
      ])
    end

    it "adds a revision with a negative value" do
      history.set_value(10)
      history.set_value(-20)

      expect(history_entries).to eq([
        ["original", nil, nil, 10],
        ["revised", nil, nil, -20]
      ])
    end

    it "modifies the revision on all further updates" do
      history.set_value(10)
      history.set_value(20)
      history.set_value(30)

      expect(history_entries).to eq([
        ["original", nil, nil, 10],
        ["revised", nil, nil, 30]
      ])
    end

    it "modifies the revision with a zero value" do
      history.set_value(10)
      history.set_value(20)
      history.set_value(0)

      expect(history_entries).to eq([
        ["original", nil, nil, 10],
        ["revised", nil, nil, 0]
      ])
    end

    it "modifies the revision with a negative value" do
      history.set_value(10)
      history.set_value(20)
      history.set_value(-30)

      expect(history_entries).to eq([
        ["original", nil, nil, 10],
        ["revised", nil, nil, -30]
      ])
    end

    it "does not create a revision if the value is unchanged" do
      history.set_value(10)
      history.set_value(10)

      expect(history_entries).to eq([
        ["original", nil, nil, 10]
      ])
    end

    it "does not associate created records with a report" do
      reporting_cycle.tick
      history.set_value(10)

      expect(history_entries).to eq([
        ["original", nil, nil, 10]
      ])
    end

    it "does not create a historical event when the value is changed outside of the current reporting period" do
      reporting_cycle.tick
      history.set_value(10)

      expect { history.set_value(20) }.to not_create_a_historical_event
    end
  end

  context "for a level C activity, owned by a delivery partner" do
    let(:partner_organisation) { create(:delivery_partner_organisation) }
    let(:activity) { create(:project_activity, organisation: partner_organisation) }

    before { reporting_cycle.tick }

    it "begins with no entries" do
      expect(history_entries).to eq([])
    end

    it "raises an error when no editable report exists" do
      Report.update_all(state: :approved)
      expect { history.set_value(10) }.to raise_error(ForecastHistory::SequenceError)
    end

    it "raises an error when reporting forecasts for the quarter of the current report" do
      history = ForecastHistory.new(activity, financial_quarter: 1, financial_year: 2015)
      expect { history.set_value(10) }.to raise_error(ForecastHistory::SequenceError)
    end

    it "raises an error when reporting forecasts for a quarter earlier than the current report" do
      history = ForecastHistory.new(activity, financial_quarter: 4, financial_year: 2014)
      expect { history.set_value(10) }.to raise_error(ForecastHistory::SequenceError)
    end

    it "creates an original entry when the value is first set" do
      history.set_value(10)

      expect(history_entries).to eq([
        ["original", 1, 2015, 10]
      ])
    end

    it "does not create a historical event when the value is first set" do
      expect { history.set_value(20) }.to not_create_a_historical_event
    end

    it "returns a _Forecast_" do
      expect(history.set_value(10)).to be_a(Forecast)
    end

    it "does not create an original entry with a zero value" do
      history.set_value(0)
      expect(history_entries).to eq([])
    end

    context "when the forecast belongs to the current report" do
      before do
        history.set_value(10)
      end

      it "edits an original entry" do
        history.set_value(20)

        expect(history_entries).to eq([
          ["original", 1, 2015, 20]
        ])
      end

      it "deletes an original entry with a zero value" do
        history.set_value(0)

        expect(history_entries).to eq([])
      end

      it "does not create a historical event when the value is first set" do
        expect { history.set_value(20) }.to not_create_a_historical_event
      end
    end

    context "when the original entry is part of an approved report" do
      before do
        history.set_value(10)
        reporting_cycle.tick
      end

      it "adds a revision" do
        history.set_value(20)

        expect(history_entries).to eq([
          ["original", 1, 2015, 10],
          ["revised", 2, 2015, 20]
        ])
      end

      it "adds a revision with a zero value" do
        history.set_value(0)

        expect(history_entries).to eq([
          ["original", 1, 2015, 10],
          ["revised", 2, 2015, 0]
        ])
      end

      it "adds a revision with a zero value when a forecast is deleted" do
        history.clear

        expect(history_entries).to eq([
          ["original", 1, 2015, 10],
          ["revised", 2, 2015, 0]
        ])
      end

      it "edits a revision when it belongs to the current report" do
        history.set_value(20)
        history.set_value(30)

        expect(history_entries).to eq([
          ["original", 1, 2015, 10],
          ["revised", 2, 2015, 30]
        ])
      end

      it "edits a revision with a zero value when it belongs to the current report" do
        history.set_value(20)
        history.set_value(0)

        expect(history_entries).to eq([
          ["original", 1, 2015, 10],
          ["revised", 2, 2015, 0]
        ])
      end

      it "deleting a forecast edits a revision with a zero value when it belongs to the current report" do
        history.set_value(20)
        history.clear

        expect(history_entries).to eq([
          ["original", 1, 2015, 10],
          ["revised", 2, 2015, 0]
        ])
      end

      it "adds a revision when the last revision is part of an approved report" do
        history.set_value(20)
        3.times { reporting_cycle.tick }

        history.set_value(30)

        expect(history_entries).to eq([
          ["original", 1, 2015, 10],
          ["revised", 2, 2015, 20],
          ["revised", 1, 2016, 30]
        ])
      end

      it "records a historical event when the last revision is part of an approved report" do
        expect { history.set_value(20) }.to create_a_historical_forecast_event(
          financial_quarter: FinancialQuarter.new(2020, 3),
          activity: activity,
          previous_value: 10,
          new_value: 20,
          report: Report.editable_for_activity(activity)
        )
      end
    end

    context "when the original entry is part of an older approved report" do
      before do
        history.set_value(10)
        6.times { reporting_cycle.tick }
      end

      it "adds a revision" do
        history.set_value(20)

        expect(history_entries).to eq([
          ["original", 1, 2015, 10],
          ["revised", 3, 2016, 20]
        ])
      end

      it "records a historical event when the last revision is part of an approved report" do
        expect { history.set_value(20) }.to create_a_historical_forecast_event(
          financial_quarter: FinancialQuarter.new(2020, 3),
          activity: activity,
          previous_value: 10,
          new_value: 20,
          report: Report.editable_for_activity(activity)
        )
      end
    end
  end

  context "adding data to a specific report" do
    let(:partner_organisation) { create(:delivery_partner_organisation) }
    let(:activity) { create(:project_activity, organisation: partner_organisation) }
    let(:edited_report) { Report.in_historical_order.first }

    before do
      reporting_cycle.tick
      Report.update_all(state: :in_review)
    end

    it "allows data to be added to the given report" do
      history.set_value(10)

      expect(history_entries).to eq([
        ["original", 1, 2015, 10]
      ])
    end

    it "does not create a historical event when the value is first set" do
      expect { history.set_value(10) }.to not_create_a_historical_event
    end
  end

  context "for a level C activity whose history includes a historic report" do
    let(:partner_organisation) { create(:delivery_partner_organisation) }
    let(:activity) { create(:project_activity, organisation: partner_organisation) }

    before do
      reporting_cycle.tick
      Report.update_all(financial_quarter: nil, financial_year: nil)
    end

    it "begins with no entries" do
      expect(history_entries).to eq([])
    end

    it "raises an error when no editable report exists" do
      Report.update_all(state: :approved)
      expect { history.set_value(10) }.to raise_error(ForecastHistory::SequenceError)
    end

    it "creates an original entry when the value is first set" do
      history.set_value(10)

      expect(history_entries).to eq([
        ["original", nil, nil, 10]
      ])
    end

    it "does not create a historical event when the value is first set" do
      expect { history.set_value(10) }.to not_create_a_historical_event
    end

    it "edits an original entry when it belongs to the current report" do
      history.set_value(10)
      history.set_value(20)

      expect(history_entries).to eq([
        ["original", nil, nil, 20]
      ])
    end

    it "does not create a historical event when it belongs to the current report" do
      history.set_value(10)
      expect { history.set_value(20) }.to not_create_a_historical_event
    end

    context "when the original entry is part of an approved report" do
      before do
        history.set_value(10)
        reporting_cycle.tick
      end

      it "adds a revision" do
        history.set_value(20)

        expect(history_entries).to eq([
          ["original", nil, nil, 10],
          ["revised", 2, 2015, 20]
        ])
      end

      it "records a historical event when adding a revision" do
        expect { history.set_value(20) }.to create_a_historical_forecast_event(
          financial_quarter: FinancialQuarter.new(2020, 3),
          activity: activity,
          previous_value: 10,
          new_value: 20,
          report: Report.editable_for_activity(activity)
        )
      end

      it "edits a revision" do
        history.set_value(20)
        history.set_value(30)

        expect(history_entries).to eq([
          ["original", nil, nil, 10],
          ["revised", 2, 2015, 30]
        ])
      end
    end
  end
end
