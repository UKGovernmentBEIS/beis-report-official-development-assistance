RSpec.describe CommitmentHelper, type: :helper do
  describe "#infer_transaction_date_from_activity_attributes" do
    context "when the specified activity has a `planned_start_date`" do
      let(:activity) { build(:project_activity, planned_start_date: "2023-02-20") }

      it "returns the planned start date" do
        expect(
          helper.infer_transaction_date_from_activity_attributes(activity)
        ).to eq(activity.planned_start_date)
      end
    end

    context "when the specified activity has an `actual_start_date` with no `planned_start_date`" do
      let(:activity) {
        build(:project_activity, planned_start_date: nil, actual_start_date: "2023-02-20")
      }

      it "returns the actual start date" do
        expect(
          helper.infer_transaction_date_from_activity_attributes(activity)
        ).to eq(activity.actual_start_date)
      end
    end

    context "when the specified activity unexpectedly has neither `actual_start_date` nor `planned_start_date`" do
      let(:activity) {
        build(
          :project_activity,
          planned_start_date: nil,
          actual_start_date: nil,
          created_at: Time.zone.parse("21-Feb-2023 12:08:00")
        )
      }

      it "returns the date the activity was created" do
        expect(
          helper.infer_transaction_date_from_activity_attributes(activity)
        ).to eq(activity.created_at.to_date)
      end
    end
  end
end
