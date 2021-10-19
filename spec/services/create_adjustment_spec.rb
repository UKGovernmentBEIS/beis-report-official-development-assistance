require "rails_helper"

RSpec.describe CreateAdjustment do
  let(:activity) { double("activity", id: "xyz321") }
  let(:report) { double("report", state: "active", id: "abc123") }
  let(:user) { double("user") }
  let(:adjustment) do
    double(
      "adjustment",
      errors: [],
      build_comment: double,
      build_detail: double,
      parent_activity: activity,
    )
  end

  let(:creator) { described_class.new(activity: activity) }

  let(:history_recorder) do
    instance_double(HistoryRecorder, call: double)
  end

  describe "#call" do
    before do
      allow(Report).to receive(:find).and_return(report)
      allow(Report).to receive(:for_activity).and_return([report])
      allow(Adjustment).to receive(:new).and_return(adjustment)
      allow(adjustment).to receive(:save).and_return(adjustment)
      allow(HistoryRecorder).to receive(:new).and_return(history_recorder)
    end

    let(:valid_attributes) do
      {report: report,
       value: BigDecimal("100.01"),
       comment: "A typo in the original value",
       user: user,
       adjustment_type: "Actual",
       financial_quarter: 2,
       financial_year: 2020,}
    end

    it "uses Report#for_activity to verify that the given report is associated " \
          "with the given Activity" do
      creator.call(attributes: valid_attributes)

      expect(Report).to have_received(:for_activity).with(activity)
    end

    it "initialises an Adjustment with the given attrs" do
      creator.call(attributes: valid_attributes)

      expect(Adjustment).to have_received(:new).with(
        parent_activity: activity,
        report: report,
        value: BigDecimal("100.01"),
        financial_quarter: 2,
        financial_year: 2020
      )
    end

    it "builds a comment" do
      creator.call(attributes: valid_attributes)

      expect(adjustment).to have_received(:build_comment)
        .with(
          body: "A typo in the original value",
          commentable: adjustment,
          report: report
        )
    end

    it "builds a detail with the user and the adjustment type" do
      creator.call(attributes: valid_attributes)

      expect(adjustment).to have_received(:build_detail)
        .with(
          user: user,
          adjustment_type: "Actual"
        )
    end

    it "attempts to persist the new Adjustment" do
      creator.call(attributes: valid_attributes)

      expect(adjustment).to have_received(:save)
    end

    context "when creation is successful" do
      it "returns a Result object with a *true* flag" do
        expect(creator.call(attributes: valid_attributes)).to eq(
          Result.new(true, adjustment)
        )
      end

      it "asks the HistoryRecorder to handle the changes" do
        changes_to_tracked_attributes = {
          value: [nil, valid_attributes.fetch(:value)],
          financial_quarter: [nil, valid_attributes.fetch(:financial_quarter)],
          financial_year: [nil, valid_attributes.fetch(:financial_year)],
          comment: [nil, valid_attributes.fetch(:comment)],
          adjustment_type: [nil, valid_attributes.fetch(:adjustment_type)],
        }

        creator.call(attributes: valid_attributes)

        expect(HistoryRecorder).to have_received(:new).with(user: user)
        expect(history_recorder).to have_received(:call).with(
          changes: changes_to_tracked_attributes,
          reference: "Adjustment to Actual",
          activity: adjustment.parent_activity,
          trackable: adjustment,
          report: report
        )
      end
    end

    context "when creation is unsuccessful" do
      before { allow(adjustment).to receive(:errors).and_return(["validation error"]) }

      it "returns a Result object with a *false* flag" do
        expect(creator.call(attributes: valid_attributes)).to eq(
          Result.new(false, adjustment)
        )
      end

      it "does NOT ask the HistoryRecorder to handle the changes" do
        creator.call(attributes: valid_attributes)

        expect(HistoryRecorder).not_to have_received(:new)
      end
    end

    context "when an error is raised by the Adjustment model" do
      before do
        allow(Adjustment).to receive(:new).and_raise(
          Exception, "Unexpected error"
        )
      end

      it "allows the error to bubble up to the caller" do
        expect { creator.call(attributes: valid_attributes) }
          .to raise_error(Exception, "Unexpected error")
      end
    end

    context "when the given report is not in the *active* state" do
      before do
        allow(report).to receive(:state).and_return("approved")
      end

      it "raises an error with a message identifying the problem report" do
        expect { creator.call(attributes: {report: report}) }
          .to raise_error(
            CreateAdjustment::AdjustmentError,
            "Report #abc123 is not in the active state"
          )
      end

      it "does not try to create an Adjustment" do
        begin
          creator.call(attributes: {report: report})
        rescue CreateAdjustment::AdjustmentError
          # we're interested in what does or doesn't happen after the error is raised
        end

        expect(Adjustment).not_to have_received(:new)
      end
    end

    context "when the given report is not associated with the activity" do
      before { allow(Report).to receive(:for_activity).and_return([]) }

      it "raises an error with a message identifying the problem report" do
        expect { creator.call(attributes: {report: report}) }
          .to raise_error(
            CreateAdjustment::AdjustmentError,
            "Report #abc123 is not associated with Activity #xyz321"
          )
      end

      it "does not try to create an Adjustment" do
        begin
          creator.call(attributes: {report: report})
        rescue CreateAdjustment::AdjustmentError
          # we're interested in what does or doesn't happen after the error is raised
        end

        expect(Adjustment).not_to have_received(:new)
      end
    end
  end
end
