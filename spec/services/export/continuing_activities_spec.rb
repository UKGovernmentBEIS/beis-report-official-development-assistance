RSpec.describe Export::ContinuingActivities do
  let(:export) { Export::ContinuingActivities.new }

  describe "#activities" do
    context "a completed activity" do
      let!(:project) { create(:project_activity, programme_status: "completed") }

      context "without actual spend" do
        it "is not included" do
          expect(export.activities).to_not include(project)
        end
      end

      context "with actual spend before or including in FQ4 2022-2023" do
        before { create(:actual, parent_activity: project, date: FinancialQuarter.new(2022, 4).end_date) }

        it "is not included" do
          expect(export.activities).to_not include(project)
        end
      end

      context "with actual spend after FQ4 2022-2023" do
        before { create(:actual, parent_activity: project, date: FinancialQuarter.new(2023, 1).start_date) }

        it "is included" do
          expect(export.activities).to include(project)
        end
      end
    end

    context "a spend_in_progress activity" do
      let!(:project) { create(:project_activity, programme_status: "spend_in_progress") }

      context "without actual spend" do
        it "is included" do
          expect(export.activities).to include(project)
        end
      end

      context "with actual spend before or including in FQ4 2022-2023" do
        before { create(:actual, parent_activity: project, date: FinancialQuarter.new(2022, 4).end_date) }

        it "is included" do
          expect(export.activities).to include(project)
        end
      end

      context "with actual spend after FQ4 2022-2023" do
        before { create(:actual, parent_activity: project, date: FinancialQuarter.new(2023, 1).start_date) }

        it "is included" do
          expect(export.activities).to include(project)
        end
      end

      context "for ISPF non-ODA" do
        before { project.update(is_oda: false) }

        it "is not included" do
          expect(export.activities).to_not include(project)
        end
      end
    end

    context "a paused activity" do
      let!(:project) { create(:project_activity, programme_status: "paused") }

      context "with neither actual spend nor forecasts" do
        it "is not included" do
          expect(export.activities).to_not include(project)
        end
      end

      context "with actual spend before or including in FQ4 2022-2023 and no forecasts" do
        before { create(:actual, parent_activity: project, date: FinancialQuarter.new(2022, 4).end_date) }

        it "is not included" do
          expect(export.activities).to_not include(project)
        end
      end

      context "with actual spend after FQ4 2022-2023 and no forecasts" do
        before { create(:actual, parent_activity: project, date: FinancialQuarter.new(2023, 1).start_date) }

        it "is included" do
          expect(export.activities).to include(project)
        end
      end

      context "with forecasts before or including in FQ4 2022-2023 and no actual spend" do
        before do
          ReportingCycle.new(project, 2, 2022).tick
          # initialising a reporting cycle like that and "tick"ing over the report cycle
          # gives us a report for FQ3 2022-2023, in which we can report a forecast for FQ4 2022-2023
          forecast_history = ForecastHistory.new(project, financial_quarter: 4, financial_year: 2022)
          forecast_history.set_value(1000)
        end

        it "is not included" do
          expect(export.activities).to_not include(project)
        end
      end

      context "with forecasts after FQ4 2022-2023 and no actual spend" do
        before do
          ReportingCycle.new(project, 3, 2022).tick
          # initialising a reporting cycle like that and "tick"ing over the report cycle
          # gives us a report for FQ4 2022-2023, in which we can report a forecast for FQ1 2023-2024
          forecast_history = ForecastHistory.new(project, financial_quarter: 1, financial_year: 2023)
          forecast_history.set_value(1000)
        end

        it "is included" do
          expect(export.activities).to include(project)
        end
      end
    end
  end
end
