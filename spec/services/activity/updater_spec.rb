require "rails_helper"

RSpec.describe Activity::Updater do
  subject(:updater) { Activity::Updater.new(activity: programme, params: params) }

  describe "#update" do
    describe "setting a commitment" do
      let(:programme) { build(:programme_activity, commitment: Commitment.new) }

      context "with valid params" do
        let(:params) {
          ActionController::Parameters.new({
            "activity" => {
              "commitment" => {"value" => "1000"},
              "activity_id" => programme.id
            }
          })
        }

        it "sets the commitment on an activity" do
          updater.update(:commitment)

          expect(programme.commitment.value).to eq(1000)
          expect(programme.commitment.transaction_date).to eq(programme.planned_start_date)
        end
      end

      context "with invalid params" do
        let(:programme) { build(:programme_activity, commitment: Commitment.new) }

        let(:params) {
          ActionController::Parameters.new({
            "activity" => {
              "commitment" => {"value" => "I'm not valid!"},
              "activity_id" => programme.id
            }
          })
        }

        it "swallows the error and adds it to the activity's errors" do
          updater.update(:commitment)

          expect(programme.errors.full_messages.first).to eq(
            "Value Validation failed: Value Value is not a number"
          )
        end
      end
    end
  end
end
