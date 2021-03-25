RSpec.describe PlannedDisbursementHistory do
  let(:edited_report) { nil }
  let(:history) { PlannedDisbursementHistory.new(activity, financial_quarter: 3, financial_year: 2020, report: edited_report) }
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

    it "does not create an original entry with a zero value" do
      history.set_value(0)
      expect(history_entries).to eq([])
    end

    it "adds a revision when the value is first updated" do
      history.set_value(10)
      history.set_value(20)

      expect(history_entries).to eq([
        ["original", nil, nil, 10],
        ["revised", nil, nil, 20],
      ])
    end

    it "adds a revision with a zero value" do
      history.set_value(10)
      history.set_value(0)

      expect(history_entries).to eq([
        ["original", nil, nil, 10],
        ["revised", nil, nil, 0],
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

    it "modifies the revision with a zero value" do
      history.set_value(10)
      history.set_value(20)
      history.set_value(0)

      expect(history_entries).to eq([
        ["original", nil, nil, 10],
        ["revised", nil, nil, 0],
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

    context "when deleting a report" do
      it "deletes the original planned disbursement when there is only one entry" do
        history.set_value(10)

        history.clear!

        expect(history_entries).to eq([])
      end

      it "deletes the original and revised entries when a forecast has been revised" do
        history.set_value(10)
        history.set_value(5)

        history.clear!

        expect(history_entries).to eq([])
      end

      it "deletes the original and revised entries when a forecast has been revised multiple times" do
        history.set_value(10)
        history.set_value(5)
        history.set_value(7)

        history.clear!

        expect(history_entries).to eq([])
      end

      it "creates a public activity record for each deleted entry" do
        PublicActivity.with_tracking do
          history.set_value(10)
          history.set_value(5)

          old_entries = history.all_entries

          expect { history.clear! }.to change { PublicActivity::Activity.where(key: "planned_disbursement.destroy").count }.by(2)

          activities = PublicActivity::Activity.where(key: "planned_disbursement.destroy").order(created_at: :desc)

          first_activity = activities.first
          second_activity = activities.second

          expect(first_activity.trackable_id).to eq(old_entries.first.id)
          expect(first_activity.parameters).to eq({associated_activity_id: activity.id})

          expect(second_activity.trackable_id).to eq(old_entries.last.id)
          expect(second_activity.parameters).to eq({associated_activity_id: activity.id})
        end
      end
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
      history = PlannedDisbursementHistory.new(activity, financial_quarter: 1, financial_year: 2015)
      expect { history.set_value(10) }.to raise_error(PlannedDisbursementHistory::SequenceError)
    end

    it "raises an error when reporting forecasts for a quarter earlier than the current report" do
      history = PlannedDisbursementHistory.new(activity, financial_quarter: 4, financial_year: 2014)
      expect { history.set_value(10) }.to raise_error(PlannedDisbursementHistory::SequenceError)
    end

    it "creates an original entry when the value is first set" do
      history.set_value(10)

      expect(history_entries).to eq([
        ["original", 1, 2015, 10],
      ])
    end

    it "does not create an original entry with a zero value" do
      history.set_value(0)
      expect(history_entries).to eq([])
    end

    it "edits an original entry when it belongs to the current report" do
      history.set_value(10)
      history.set_value(20)

      expect(history_entries).to eq([
        ["original", 1, 2015, 20],
      ])
    end

    it "deletes an original entry with a zero value when it belongs to the current report" do
      history.set_value(10)
      history.set_value(0)

      expect(history_entries).to eq([])
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

    it "adds a revision with a zero value when the original is part of an approved report" do
      history.set_value(10)
      reporting_cycle.tick

      history.set_value(0)

      expect(history_entries).to eq([
        ["original", 1, 2015, 10],
        ["revised", 2, 2015, 0],
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

    it "edits a revision with a zero value when it belongs to the current report" do
      history.set_value(10)
      reporting_cycle.tick

      history.set_value(20)
      history.set_value(0)

      expect(history_entries).to eq([
        ["original", 1, 2015, 10],
        ["revised", 2, 2015, 0],
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

  context "adding data to a specific report" do
    let(:delivery_partner) { create(:delivery_partner_organisation) }
    let(:activity) { create(:project_activity, organisation: delivery_partner) }
    let(:edited_report) { Report.in_historical_order.first }

    before do
      reporting_cycle.tick
      Report.update_all(state: :in_review)
    end

    it "allows data to be added to the given report" do
      history.set_value(10)

      expect(history_entries).to eq([
        ["original", 1, 2015, 10],
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
