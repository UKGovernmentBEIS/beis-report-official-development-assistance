RSpec.describe "rake activities:delete", type: :task do
  let(:user) { create(:beis_user) }

  it "returns an error if the ID is blank" do
    expect { task.execute }.to raise_error(SystemExit, /You must specify a database ID/)
  end

  it "returns an error if the activity cannot be found" do
    ClimateControl.modify ID: "NOT-AN-ID" do
      expect { task.execute }.to raise_error(SystemExit, /Cannot find an activity with ID/)
    end
  end

  describe "#delete_activity" do
    before do
      load "lib/tasks/delete_activity.rake"
    end

    it "deletes the activity" do
      activity = create(:project_activity)
      expect { delete_activity(activity_id: activity.id) }.to change { Activity.count }.by(-1)
    end

    it "deletes any actuals" do
      activity = create(:project_activity)
      create_list(:actual, 5, parent_activity_id: activity.id)

      expect { delete_activity(activity_id: activity.id) }.to change { Actual.count }.by(-5)
      expect(Actual.where(parent_activity_id: activity.id).count).to eq 0
    end

    it "deletes actual adjustments" do
      activity = create(:project_activity)
      adjustment = create(:adjustment, :actual, parent_activity_id: activity.id)

      expect { delete_activity(activity_id: activity.id) }.to change { Adjustment.count }.by(-1)
      expect(Adjustment.where(parent_activity_id: activity.id).count).to eq 0
      expect(AdjustmentDetail.where(adjustment_id: adjustment.id).count).to eq 0
    end

    it "deletes refunds" do
      activity = create(:project_activity)
      create_list(:refund, 5, parent_activity_id: activity.id)

      expect { delete_activity(activity_id: activity.id) }.to change { Refund.count }.by(-5)
      expect(Refund.where(parent_activity_id: activity.id).count).to eq 0
    end

    it "deletes refund adjustments" do
      activity = create(:project_activity)
      adjustment = create(:adjustment, :refund, parent_activity_id: activity.id)

      expect { delete_activity(activity_id: activity.id) }.to change { Adjustment.count }.by(-1)
      expect(Adjustment.where(parent_activity_id: activity.id).count).to eq 0
      expect(AdjustmentDetail.where(adjustment_id: adjustment.id).count).to eq 0
    end

    it "deletes budgets" do
      activity = create(:project_activity)
      create(:budget, parent_activity_id: activity.id)

      expect { delete_activity(activity_id: activity.id) }.to change { Budget.count }.by(-1)
      expect(Budget.where(parent_activity_id: activity.id).count).to eq 0
    end

    it "deletes forecasts and history" do
      activity = create(:project_activity)
      reporting_cycle = ReportingCycle.new(activity, 1, 2018)

      forecast = ForecastHistory.new(activity, financial_quarter: 4, financial_year: 2018)

      reporting_cycle.tick
      forecast.set_value(5_000)

      reporting_cycle.tick
      forecast.set_value(2_500)

      expect(Forecast.unscoped.count).to eq 2
      expect { delete_activity(activity_id: activity.id) }.to change { Forecast.unscoped.count }.by(-2)
      expect(Forecast.unscoped.where(parent_activity_id: activity.id).count).to eq 0
    end

    it "deletes activity comments" do
      activity = create(:project_activity)
      create_list(:comment, 5, commentable: activity, commentable_type: "Activity")
      expect { delete_activity(activity_id: activity.id) }.to change { Comment.count }.by(-5)
      expect(Comment.where(commentable: activity.id).count).to eq 0
    end

    it "deletes refund comments" do
      activity = create(:project_activity)
      refund = create(:refund, parent_activity_id: activity.id)

      expect(Comment.where(commentable_id: refund.id).count).to eq 1
      expect { delete_activity(activity_id: activity.id) }.to change { Comment.count }.by(-1)
      expect(Comment.where(commentable_id: refund.id).count).to eq 0
    end

    it "deletes adjustment comments" do
      activity = create(:project_activity)
      adjustment = create(:adjustment, parent_activity_id: activity.id)

      expect(Comment.where(commentable_id: adjustment.id).count).to eq 1
      expect { delete_activity(activity_id: activity.id) }.to change { Comment.count }.by(-1)
      expect(Comment.where(commentable_id: adjustment.id).count).to eq 0
    end

    it "deletes matched effort" do
      activity = create(:project_activity)
      create(:matched_effort, activity_id: activity.id)

      expect { delete_activity(activity_id: activity.id) }.to change { MatchedEffort.count }.by(-1)
      expect(MatchedEffort.where(activity_id: activity.id).count).to eq 0
    end

    it "deletes external income" do
      activity = create(:project_activity)
      create(:external_income, activity_id: activity.id)

      expect { delete_activity(activity_id: activity.id) }.to change { ExternalIncome.count }.by(-1)
      expect(ExternalIncome.where(activity_id: activity.id).count).to eq 0
    end

    it "deletes incomming transfers" do
      activity = create(:project_activity)
      create(:incoming_transfer, destination_id: activity.id)

      expect { delete_activity(activity_id: activity.id) }.to change { IncomingTransfer.count }.by(-1)
      expect(IncomingTransfer.where(destination_id: activity.id).count).to eq 0
    end

    it "deletes outgoing_transfers" do
      activity = create(:project_activity)
      create(:outgoing_transfer, source_id: activity.id)

      expect { delete_activity(activity_id: activity.id) }.to change { OutgoingTransfer.count }.by(-1)
      expect(OutgoingTransfer.where(source_id: activity.id).count).to eq 0
    end

    it "deletes the child acitivities" do
      activity = create(:project_activity)
      create(:third_party_project_activity, parent: activity)

      expect { delete_activity(activity_id: activity.id) }.to change { Activity.count }.by(-2)
    end
  end
end
