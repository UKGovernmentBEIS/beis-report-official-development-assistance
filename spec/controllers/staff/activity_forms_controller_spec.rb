require "rails_helper"

RSpec.describe Staff::ActivityFormsController do
  let(:user) { create(:delivery_partner_user, organisation: organisation) }
  let(:organisation) { create(:partner_organisation) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
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
          let(:activity) { create(:project_activity, organisation: organisation, parent: fund, source_fund_code: Fund.by_short_name("GCRF").id) }

          it { is_expected.to render_current_step }
        end
      end

      context "gcrf_strategic_area step" do
        subject { get_step :gcrf_strategic_area }

        it { is_expected.to skip_to_next_step }

        context "when activity is the GCRF fund" do
          let(:activity) { create(:project_activity, organisation: organisation, parent: fund, source_fund_code: Fund.by_short_name("GCRF").id) }

          it { is_expected.to render_current_step }
        end
      end

      context "collaboration_type" do
        subject { get_step :collaboration_type }

        context "when the field is not editable" do
          before do
            allow(Activity::Inference.service).to receive(:editable?).with(activity, :collaboration_type).and_return(false)
          end

          it { is_expected.to skip_to_next_step }
        end

        context "when the field is editable" do
          before do
            allow(Activity::Inference.service).to receive(:editable?).with(activity, :collaboration_type).and_return(true)
          end

          it { is_expected.to render_current_step }
        end
      end

      context "collaboration_type" do
        subject { get_step :fstc_applies }

        context "when the field is not editable" do
          before do
            allow(Activity::Inference.service).to receive(:editable?).with(activity, :fstc_applies).and_return(false)
          end

          it { is_expected.to skip_to_next_step }
        end

        context "when the field is editable" do
          before do
            allow(Activity::Inference.service).to receive(:editable?).with(activity, :fstc_applies).and_return(true)
          end

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
          let(:activity) { create(:project_activity, organisation: organisation, parent: programme, source_fund_code: Fund.by_short_name("GCRF").id) }

          it { is_expected.to render_current_step }
        end
      end

      context "channel_of_delivery_code" do
        subject { get_step :channel_of_delivery_code }

        context "when the field is not editable" do
          before do
            allow(Activity::Inference.service).to receive(:editable?).with(activity, :channel_of_delivery_code).and_return(false)
          end

          it { is_expected.to skip_to_next_step }
        end

        context "when the field is editable" do
          before do
            allow(Activity::Inference.service).to receive(:editable?).with(activity, :channel_of_delivery_code).and_return(true)
          end

          it { is_expected.to render_current_step }
        end
      end

      context "country_delivery_partners" do
        subject { get_step :country_delivery_partners }

        context "when the activity is newton funded" do
          let(:activity) { create(:project_activity, :newton_funded, organisation: organisation, parent: programme) }

          it { is_expected.to render_current_step }
        end

        context "when the activity is GCRF funded" do
          let(:activity) { create(:project_activity, :gcrf_funded, organisation: organisation, parent: programme) }

          it { is_expected.to skip_to_next_step }
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
          let(:activity) { create(:project_activity, organisation: organisation, parent: programme, source_fund_code: Fund.by_short_name("GCRF").id) }

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
    let(:report) { double("report") }

    before do
      policy = instance_double(ActivityPolicy, update?: true)
      allow(ActivityPolicy).to receive(:new).and_return(policy)
      allow(Report).to receive(:editable_for_activity).and_return(report)
      allow(HistoryRecorder).to receive(:new).and_return(history_recorder)
    end

    context "when updating 'purpose' causes #title and #description to be updated" do
      let(:expected_changes) do
        {
          "title" => ["Original title", "Updated title"],
          "description" => ["Original description", "Updated description"]
        }
      end

      it "finds the appropriate report to be associated with the changes" do
        put_step(:purpose, {title: "Updated title", description: "Updated description"})

        expect(Report).to have_received(:editable_for_activity).with(activity)
      end

      it "asks the HistoryRecorder to record the changes" do
        put_step(:purpose, {title: "Updated title", description: "Updated description"})

        expect(HistoryRecorder).to have_received(:new).with(user: user)
        expect(history_recorder).to have_received(:call).with(
          changes: expected_changes,
          reference: "Update to Activity purpose",
          activity: activity,
          trackable: activity,
          report: report
        )
      end
    end

    context "when the activity is invalid" do
      before do
        allow(Activity).to receive(:find).and_return(activity)
        allow(activity).to receive(:valid?).and_return(false)
      end

      subject { put_step(:purpose, {title: "Updated title", description: "Updated description"}) }

      it { is_expected.to render_current_step }
    end

    context "when the activity is valid" do
      before do
        allow(Activity).to receive(:find).and_return(activity)
        allow(activity).to receive(:valid?).and_return(true)
        allow(activity).to receive(:form_steps_completed?).and_return(false)
      end

      subject { put_step(:purpose, {title: "Updated title", description: "Updated description"}) }

      it { is_expected.to skip_to_next_step }
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
