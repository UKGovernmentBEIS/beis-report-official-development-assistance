require "rails_helper"

RSpec.describe Staff::ActivityFormsController do
  let(:user) { create(:delivery_partner_user, organisation: organisation) }
  let(:organisation) { create(:delivery_partner_organisation) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:logged_in_using_omniauth?).and_return(true)
  end

  describe "#show" do
    context "when editing a programme" do
      let(:user) { create(:beis_user) }

      let(:fund) { create(:fund_activity) }
      let(:activity) { create(:programme_activity, parent: fund) }

      context "gcrf_challenge_area step" do
        subject { get_step :gcrf_challenge_area }

        it { is_expected.to skip_to_next_step }

        context "when activity is the GCRF fund" do
          let(:activity) { create(:project_activity, organisation: organisation, parent: fund, source_fund_code: Fund::MAPPINGS["GCRF"]) }

          it { is_expected.to render_current_step }
        end
      end

      context "gcrf_strategic_area step" do
        subject { get_step :gcrf_strategic_area }

        it { is_expected.to skip_to_next_step }

        context "when activity is the GCRF fund" do
          let(:activity) { create(:project_activity, organisation: organisation, parent: fund, source_fund_code: Fund::MAPPINGS["GCRF"]) }

          it { is_expected.to render_current_step }
        end
      end
    end

    context "when editing a project" do
      let(:fund) { create(:fund_activity) }
      let(:programme) { create(:programme_activity, parent: fund) }
      let(:activity) { create(:project_activity, organisation: organisation, parent: programme) }

      context "gcrf_challenge_area step" do
        subject { get_step :gcrf_challenge_area }

        it { is_expected.to skip_to_next_step }

        context "when activity is associated with the GCRF fund" do
          let(:activity) { create(:project_activity, organisation: organisation, parent: programme, source_fund_code: Fund::MAPPINGS["GCRF"]) }

          it { is_expected.to render_current_step }
        end
      end
    end

    context "when editing a third-party project" do
      let(:fund) { create(:fund_activity) }
      let(:programme) { create(:programme_activity, parent: fund) }
      let(:project) { create(:project_activity, parent: programme) }
      let(:activity) { create(:third_party_project_activity, organisation: organisation, parent: project) }

      context "gcrf_challenge_area step" do
        subject { get_step :gcrf_challenge_area }

        it { is_expected.to skip_to_next_step }

        context "when activity is associated with the GCRF fund" do
          let(:activity) { create(:project_activity, organisation: organisation, parent: programme, source_fund_code: Fund::MAPPINGS["GCRF"]) }

          it { is_expected.to render_current_step }
        end
      end
    end
  end

  describe "#update" do
    let(:history_recorder) { instance_double(HistoryRecorder, call: true) }

    let(:fund) { create(:fund_activity) }
    let(:programme) { create(:programme_activity, parent: fund) }
    let(:activity) do
      create(
        :project_activity,
        title: "Original title",
        description: "Original description",
        organisation: organisation,
        parent: programme
      )
    end

    before do
      policy = instance_double(ActivityPolicy, update?: true)
      allow(ActivityPolicy).to receive(:new).and_return(policy)
      allow(HistoryRecorder).to receive(:new).and_return(history_recorder)
    end

    context "when updating 'purpose' causes #title and #description to be updated" do
      let(:expected_changes) do
        {
          "title" => ["Original title", "Updated title"],
          "description" => ["Original description", "Updated description"],
        }
      end

      it "asks the HistoryRecorder to record the changes" do
        put_step(:purpose, {title: "Updated title", description: "Updated description"})

        expect(HistoryRecorder).to have_received(:new).with(user: user)
        expect(history_recorder).to have_received(:call).with(
          changes: expected_changes,
          reference: "Update to Activity purpose",
          activity: activity
        )
      end
    end
  end

  private

  def get_step(step)
    get :show, params: {activity_id: activity.id, id: step}
  end

  def put_step(step, activity_params)
    put :update, params: {activity_id: activity.id, id: step, activity: activity_params}
  end

  RSpec::Matchers.define :skip_to_next_step do
    match do |actual|
      expect(actual).to redirect_to(controller.next_wizard_path)
    end

    description do
      "skip to the next step (#{controller.next_step})"
    end

    failure_message do |actual|
      "expected to skip the next step (#{controller.step}), but didn't"
    end
  end

  RSpec::Matchers.define :render_current_step do
    match do |actual|
      expect(actual).to render_template(controller.step)
    end

    description do
      "render the current step"
    end

    failure_message do |actual|
      "expected to render the current form step (#{controller.step}), but didn't"
    end
  end
end
