require "rails_helper"

RSpec.describe "Activity forms", type: :request do
  let(:organisation) { create(:partner_organisation) }
  let(:user) { create(:partner_organisation_user, organisation: organisation) }

  before do
    host! "test.local"
    login_as(user)
  end

  after { logout }

  let(:activity) { create(:project_activity, organisation: user.organisation, extending_organisation: user.organisation) }
  let!(:report) { create(:report, :active, organisation: user.organisation, fund: activity.associated_fund) }

  context "aid types" do
    let(:step) { :aid_type }

    before do
      activity.update(form_state: "aid_type", aid_type: nil, collaboration_type: nil)
    end

    context "when the aid type is set to 'B02'" do
      it "infers the expected fields and redirects to the sustainable development goals step" do
        put_step(step, {aid_type: "B02"})
        follow_redirect!

        expect(response).to redirect_to_step("sustainable_development_goals")

        expect(activity.reload.collaboration_type).to eq("2")
        expect(activity.reload.fstc_applies).to be(false)
        expect(activity.reload.channel_of_delivery_code).to eq("40000")
      end
    end

    context "when the aid type is set to 'B03'" do
      it "infers the expected fields  and redirects to the sustainable development goals step" do
        put_step(step, {aid_type: "B03"})
        follow_redirect!

        expect(response).to redirect_to_step("sustainable_development_goals")

        expect(activity.reload.collaboration_type).to eq("1")
        expect(activity.reload.channel_of_delivery_code).to eq("11000")
      end
    end

    ["D02", "E01"].each do |aid_type|
      context "when the aid type is set to '#{aid_type}'" do
        it "sets the FSTC applies question to true" do
          put_step(step, {aid_type: aid_type})

          expect(response).to redirect_to_next_step

          expect(activity.reload.fstc_applies).to be(true)
        end
      end
    end
  end

  context "date validation" do
    let(:step) { :dates }

    it "returns an error if the date is invalid" do
      put_step(step, {
        "planned_start_date(3i)": "01",
        "planned_start_date(2i)": "12",
        "planned_start_date(1i)": "2020",
        "planned_end_date(3i)": "01",
        "planned_end_date(2i)": "15",
        "planned_end_date(1i)": "2021"
      })

      expect(response).to_not redirect_to_next_step
      expect(response.body).to include(t("activerecord.errors.models.activity.attributes.planned_end_date.invalid"))
    end
  end

  private

  def put_step(step, activity_params)
    put activity_step_path(activity_id: activity.id, id: step), params: {activity: activity_params}
  end

  def get_step(step)
    get activity_step_path(activity_id: activity.id, id: step)
  end

  RSpec::Matchers.define :redirect_to_step do |step|
    match do |actual|
      expect(actual).to redirect_to(activity_step_path(activity_id: activity.id, id: step))
    end

    description do
      "redirect to the step #{step}"
    end

    failure_message do |actual|
      "expected to redirect to the the #{step} step, but didn't"
    end
  end

  RSpec::Matchers.define :redirect_to_next_step do
    match do |actual|
      expect(actual).to redirect_to(activity_step_path(activity_id: activity.id, id: next_step))
    end

    description do
      "redirect to the step #{step}"
    end

    failure_message do |actual|
      "expected to redirect to the the #{step} step, but didn't"
    end

    def next_step
      current_index = Activity::FORM_STEPS.index(step)
      Activity::FORM_STEPS[current_index + 1]
    end
  end
end
