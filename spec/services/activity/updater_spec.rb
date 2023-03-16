require "rails_helper"

RSpec.describe Activity::Updater do
  subject(:updater) { Activity::Updater.new(activity: activity, params: params) }

  describe "#update" do
    describe "setting a commitment" do
      context "when the activity does not yet have a commitment" do
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

      context "when the activity already has a commitment" do
        let(:activity) { create(:programme_activity, :with_commitment) }

        context "with valid params" do
          let(:params) {
            ActionController::Parameters.new({
              "activity" => {
                "commitment" => {"value" => "9999"},
                "activity_id" => activity.id
              }
            })
          }

          it "sets the commitment on an activity" do
            updater.update(:commitment)

            expect(activity.commitment.value).to eq(9999)
            expect(activity.commitment.transaction_date).to eq(activity.planned_start_date)
          end
        end

        context "with invalid params" do
          let(:previous_commitment) { build(:commitment, value: 8888, transaction_date: Date.parse("2023-02-20")) }
          let(:activity) { create(:programme_activity, commitment: previous_commitment) }

          let(:params) {
            ActionController::Parameters.new({
              "activity" => {
                "commitment" => {"value" => "I'm not valid!"},
                "activity_id" => activity.id
              }
            })
          }

          it "does not overwrite the original commitment" do
            updater.update(:commitment)

            activity.reload

            expect(activity.commitment.value).to eq(previous_commitment.value)
            expect(activity.commitment.transaction_date).to eq(previous_commitment.transaction_date)
          end
        end
      end

      ["programme", "project"].each do |level|
        context "when it's a #{level}" do
          let(:activity) { build("#{level}_activity".to_sym, commitment: Commitment.new) }

          let(:params) {
            ActionController::Parameters.new({
              "activity" => {
                "commitment" => {"value" => ""},
                "activity_id" => activity.id
              }
            })
          }

          it "doesn't throw an error with an empty commitment value" do
            updater.update(:commitment)

            expect(activity.errors.full_messages).to be_empty
          end
        end
      end

      context "when it's a third-party project" do
        let(:activity) { build(:third_party_project_activity, commitment: Commitment.new) }

        let(:params) {
          ActionController::Parameters.new({
            "activity" => {
              "commitment" => {"value" => ""},
              "activity_id" => activity.id
            }
          })
        }

        it "throws an error with an empty commitment value" do
          updater.update(:commitment)

          expect(activity.errors.full_messages.first).to include("Value Validation failed: Value Value can't be blank")
        end
      end
    end
  end
end
