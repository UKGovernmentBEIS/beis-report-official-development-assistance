require "rails_helper"

RSpec.describe Activity::Updater do
  subject(:updater) { Activity::Updater.new(activity: activity, params: params) }

  describe "#update" do
    describe "setting a commitment" do
      let(:activity) { build(:programme_activity) }

      before { activity.build_commitment }

      context "with valid params" do
        let(:params) {
          ActionController::Parameters.new({
            "activity" => {
              "commitment" => {"value" => "1000"},
              "activity_id" => activity.id
            }
          })
        }

        it "sets the commitment on an activity" do
          updater.update(:commitment)

          expect(activity.commitment.value).to eq(1000)
          expect(activity.commitment.transaction_date).to eq(activity.planned_start_date)
        end
      end

      context "with invalid params" do
        let(:activity) { build(:programme_activity) }

        let(:params) {
          ActionController::Parameters.new({
            "activity" => {
              "commitment" => {"value" => "I'm not valid!"},
              "activity_id" => activity.id
            }
          })
        }

        before do
          updater.update(:commitment)
          activity.build_commitment
        end

        it "swallows the error and adds it to the activity's errors" do
          expect(activity.errors.full_messages.first).to eq(
            "Value Validation failed: Value Value is not a number"
          )
        end

        it "does not set the value or transaction date on the commitment" do
          expect(activity.commitment.value).to be_nil
          expect(activity.commitment.transaction_date).to be_nil
          expect(activity.commitment).not_to be_persisted
        end
      end
    end
  end
end
