require "spec_helper"
require "app/services/history_recorder"

RSpec.describe HistoryRecorder do
  describe "on instantiation" do
    it "requires a user" do
      expect { HistoryRecorder.new }.to raise_error(ArgumentError, "missing keyword: :user")
    end
  end

  describe "#call(activity:, reference:, changes:)" do
    before { allow(HistoricalEvent).to receive(:create).and_return(true) }

    subject(:recorder) do
      HistoryRecorder.new(user: user)
    end

    let(:changes) do
      {
        "title" => ["Original title", "Updated title"],
        "description" => ["Original description", "Updated description"]
      }
    end

    let(:user) { double("user") }
    let(:reference) { double("reference") }
    let(:activity) { double("activity") }
    let(:trackable) { double("trackable") }
    let(:report) { double("report") }

    it "creates a HistoricalEvent for each change provided" do
      recorder.call(
        changes: changes,
        activity: activity,
        trackable: trackable,
        reference: reference,
        report: report
      )

      expect(HistoricalEvent).to have_received(:create).with(
        user: user,
        activity: activity,
        trackable: trackable,
        report: report,
        reference: reference,
        value_changed: "title",
        previous_value: "Original title",
        new_value: "Updated title"
      )

      expect(HistoricalEvent).to have_received(:create).with(
        user: user,
        activity: activity,
        trackable: trackable,
        report: report,
        reference: reference,
        value_changed: "description",
        previous_value: "Original description",
        new_value: "Updated description"
      )
    end

    context "when the the changes include the internal Wizard 'form_state' property" do
      let(:changes) do
        {
          "objectives" => ["Original objective", "New objective"],
          "form_state" => ["purpose", "objectives"]
        }
      end

      it "does NOT create a HistoricalEvent for that particular property" do
        recorder.call(
          changes: changes,
          activity: activity,
          trackable: trackable,
          reference: reference,
          report: report
        )

        expect(HistoricalEvent).not_to have_received(:create).with(
          hash_including(
            value_changed: "form_state"
          )
        )
      end

      it "does create a HistoricalEvent for other properties in the batch" do
        recorder.call(
          changes: changes,
          activity: activity,
          trackable: trackable,
          reference: reference,
          report: report
        )

        expect(HistoricalEvent).to have_received(:create).with(
          user: user,
          activity: activity,
          trackable: trackable,
          report: report,
          reference: reference,
          value_changed: "objectives",
          previous_value: "Original objective",
          new_value: "New objective"
        )
      end
    end
  end
end
