RSpec.describe PlannedDisbursementHistory do
  let(:history) { PlannedDisbursementHistory.new(activity, 3, 2020) }
  let(:reporting_cycle) { ReportingCycle.new(activity, 1, 2015) }

  def history_entries
    history.all_entries.map do |entry|
      [
        entry.planned_disbursement_type,
        entry.report&.financial_quarter,
        entry.report&.financial_year,
        entry.value,
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
        ["original", nil, nil, 10],
      ])
    end

    it "adds a revision when the value is first updated" do
      history.set_value(10)
      history.set_value(20)

      expect(history_entries).to eq([
        ["original", nil, nil, 10],
        ["revised", nil, nil, 20],
      ])
    end

    it "modifies the revision on all further updates" do
      history.set_value(10)
      history.set_value(20)
      history.set_value(30)

      expect(history_entries).to eq([
        ["original", nil, nil, 10],
        ["revised", nil, nil, 30],
      ])
    end

    it "does not create a revision if the value is unchanged" do
      history.set_value(10)
      history.set_value(10)

      expect(history_entries).to eq([
        ["original", nil, nil, 10],
      ])
    end

    it "does not associate created records with a report" do
      reporting_cycle.tick
      history.set_value(10)

      expect(history_entries).to eq([
        ["original", nil, nil, 10],
      ])
    end
  end

  context "for a level C activity, owned by a delivery partner" do
    let(:delivery_partner) { create(:delivery_partner_organisation) }
    let(:activity) { create(:project_activity, organisation: delivery_partner) }

    before { reporting_cycle.tick }

    it "begins with no entries" do
      expect(history_entries).to eq([])
    end

    it "raises an error when no editable report exists" do
      Report.update_all(state: :approved)
      expect { history.set_value(10) }.to raise_error(PlannedDisbursementHistory::SequenceError)
    end

    it "raises an error when reporting forecasts for the quarter of the current report" do
      history = PlannedDisbursementHistory.new(activity, 1, 2015)
      expect { history.set_value(10) }.to raise_error(PlannedDisbursementHistory::SequenceError)
    end

    it "raises an error when reporting forecasts for a quarter earlier than the current report" do
      history = PlannedDisbursementHistory.new(activity, 4, 2014)
      expect { history.set_value(10) }.to raise_error(PlannedDisbursementHistory::SequenceError)
    end

    it "creates an original entry when the value is first set" do
      history.set_value(10)

      expect(history_entries).to eq([
        ["original", 1, 2015, 10],
      ])
    end

    it "edits an original entry when it belongs to the current report" do
      history.set_value(10)
      history.set_value(20)

      expect(history_entries).to eq([
        ["original", 1, 2015, 20],
      ])
    end

    it "adds a revision when the original entry is part of an approved report" do
      history.set_value(10)
      reporting_cycle.tick

      history.set_value(20)

      expect(history_entries).to eq([
        ["original", 1, 2015, 10],
        ["revised", 2, 2015, 20],
      ])
    end

    it "adds a revision when the original entry is part of an older approved report" do
      history.set_value(10)
      6.times { reporting_cycle.tick }

      history.set_value(20)

      expect(history_entries).to eq([
        ["original", 1, 2015, 10],
        ["revised", 3, 2016, 20],
      ])
    end

    it "edits a revision when it belongs to the current report" do
      history.set_value(10)
      reporting_cycle.tick

      history.set_value(20)
      history.set_value(30)

      expect(history_entries).to eq([
        ["original", 1, 2015, 10],
        ["revised", 2, 2015, 30],
      ])
    end

    it "adds a revision when the last revision is part of an approved report" do
      history.set_value(10)
      reporting_cycle.tick

      history.set_value(20)
      3.times { reporting_cycle.tick }

      history.set_value(30)

      expect(history_entries).to eq([
        ["original", 1, 2015, 10],
        ["revised", 2, 2015, 20],
        ["revised", 1, 2016, 30],
      ])
    end
  end

  context "for a level C activity whose history includes a historic report" do
    let(:delivery_partner) { create(:delivery_partner_organisation) }
    let(:activity) { create(:project_activity, organisation: delivery_partner) }

    before do
      reporting_cycle.tick
      Report.update_all(financial_quarter: nil, financial_year: nil)
    end

    it "begins with no entries" do
      expect(history_entries).to eq([])
    end

    it "raises an error when no editable report exists" do
      Report.update_all(state: :approved)
      expect { history.set_value(10) }.to raise_error(PlannedDisbursementHistory::SequenceError)
    end

    it "creates an original entry when the value is first set" do
      history.set_value(10)

      expect(history_entries).to eq([
        ["original", nil, nil, 10],
      ])
    end

    it "edits an original entry when it belongs to the current report" do
      history.set_value(10)
      history.set_value(20)

      expect(history_entries).to eq([
        ["original", nil, nil, 20],
      ])
    end

    it "adds a revision when the original entry is part of an approved report" do
      history.set_value(10)
      reporting_cycle.tick

      history.set_value(20)

      expect(history_entries).to eq([
        ["original", nil, nil, 10],
        ["revised", 2, 2015, 20],
      ])
    end

    it "edits a revision when it belongs to the current report" do
      history.set_value(10)
      reporting_cycle.tick

      history.set_value(20)
      history.set_value(30)

      expect(history_entries).to eq([
        ["original", nil, nil, 10],
        ["revised", 2, 2015, 30],
      ])
    end
  end
end
