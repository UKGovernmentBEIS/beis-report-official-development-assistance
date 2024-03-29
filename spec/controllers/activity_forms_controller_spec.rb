require "rails_helper"

RSpec.describe ActivityFormsController do
  let(:user) { create(:partner_organisation_user, organisation: organisation) }
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
          let(:activity) { create(:programme_activity, :gcrf_funded) }

          it { is_expected.to render_current_step }
        end
      end

      context "gcrf_strategic_area step" do
        subject { get_step :gcrf_strategic_area }

        it { is_expected.to skip_to_next_step }

        context "when activity is the GCRF fund" do
          let(:activity) { create(:programme_activity, :gcrf_funded) }

          it { is_expected.to render_current_step }
        end
      end

      context "ispf_themes step" do
        subject { get_step :ispf_themes }

        it { is_expected.to skip_to_next_step }

        context "when it's an ISPF activity" do
          let(:activity) { create(:programme_activity, :ispf_funded) }

          it { is_expected.to render_current_step }
        end
      end

      context "ispf_oda_partner_countries step" do
        subject { get_step :ispf_oda_partner_countries }

        it { is_expected.to skip_to_next_step }

        context "when it's an ISPF activity" do
          let(:activity) { create(:programme_activity, :ispf_funded, is_oda: true) }

          it { is_expected.to render_current_step }
        end
      end

      context "ispf_non_oda_partner_countries step" do
        subject { get_step :ispf_non_oda_partner_countries }

        it { is_expected.to skip_to_next_step }

        context "when it's an ISPF activity" do
          let(:activity) { create(:programme_activity, :ispf_funded, is_oda: false) }

          it { is_expected.to render_current_step }
        end
      end

      context "linked_activity step" do
        subject { get_step :linked_activity }

        it { is_expected.to skip_to_next_step }

        context "when the linked activity is editable" do
          let(:policy) { double(:policy) }

          before do
            allow(controller).to receive(:policy).and_return(policy)
            allow(policy).to receive(:update_linked_activity?).and_return(true)
          end

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

      context "fstc_applies" do
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

      context "tags step" do
        subject { get_step :tags }

        it { is_expected.to skip_to_next_step }

        context "when it's an ISPF activity" do
          let(:activity) { create(:programme_activity, :ispf_funded) }

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

      context "country_partner_organisations" do
        subject { get_step :country_partner_organisations }

        context "when the activity is newton funded" do
          let(:activity) { create(:project_activity, :newton_funded, organisation: organisation, parent: programme) }

          it { is_expected.to render_current_step }
        end

        context "when the activity is GCRF funded" do
          let(:activity) { create(:project_activity, :gcrf_funded, organisation: organisation, parent: programme) }

          it { is_expected.to skip_to_next_step }
        end
      end

      context "implementing_organisation step" do
        subject { get_step :implementing_organisation }

        context "when the activity is GCRF funded" do
          let(:activity) { create(:third_party_project_activity, :gcrf_funded, organisation: organisation) }

          it "completes the activity without rendering the step" do
            expect(activity.form_state).to eq("complete")
          end
        end

        context "when the project is ISPF funded" do
          let(:activity) { create(:third_party_project_activity, :ispf_funded, organisation: organisation) }

          context "and doesn't have any implementing organisations set" do
            before do
              activity.implementing_organisations = []
            end

            it { is_expected.to render_current_step }
          end

          context "and it already has at least one implementing organisation set" do
            it "completes the activity without rendering the step" do
              expect(activity.form_state).to eq("complete")
            end
          end
        end
      end

      context "linked_activity step" do
        subject { get_step :linked_activity }

        it { is_expected.to skip_to_next_step }

        context "when the linked activity is editable" do
          let(:policy) { double(:policy) }

          before do
            allow(controller).to receive(:policy).and_return(policy)
            allow(policy).to receive(:update_linked_activity?).and_return(true)
          end

          it { is_expected.to render_current_step }
        end
      end

      context "tags step" do
        subject { get_step :tags }

        it { is_expected.to skip_to_next_step }

        context "when it's an ISPF activity" do
          let(:activity) { create(:project_activity, :ispf_funded, organisation: organisation) }

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
          let(:activity) { create(:project_activity, organisation: organisation, parent: programme, source_fund_code: Fund.by_short_name("GCRF").id) }

          it { is_expected.to render_current_step }
        end
      end

      context "linked_activity step" do
        subject { get_step :linked_activity }

        it { is_expected.to skip_to_next_step }

        context "when the linked activity is editable" do
          let(:policy) { double(:policy) }

          before do
            allow(controller).to receive(:policy).and_return(policy)
            allow(policy).to receive(:update_linked_activity?).and_return(true)
          end

          it { is_expected.to render_current_step }
        end
      end

      context "tags step" do
        subject { get_step :tags }

        it { is_expected.to skip_to_next_step }

        context "when it's an ISPF activity" do
          let(:activity) { create(:third_party_project_activity, :ispf_funded, organisation: organisation) }

          it { is_expected.to render_current_step }
        end
      end
    end

    describe "commitment" do
      let(:policy) { double(:policy, show?: true) }
      let(:commitment) { create(:commitment, value: 1000) }
      let(:activity) { create(:third_party_project_activity, commitment: commitment) }

      before do
        allow(ActivityPolicy).to receive(:new).and_return(policy)
        allow(controller).to receive(:policy).and_return(policy)
      end

      context "when the commitment can be set" do
        before do
          allow(policy).to receive(:set_commitment?).and_return(true)
        end

        subject { get_step :commitment }

        it { is_expected.to render_current_step }

        context "when there is already a commitment" do
          it "does not build a new commitment when rendering the edit page" do
            subject { get_step :commitment }

            expect(activity.commitment).to eq(commitment)
          end
        end

        context "when there is no commitment" do
          let!(:activity) { create(:third_party_project_activity) }

          before do
            stub_commitment_builder
          end

          it "builds a new, empty commitment when rendering the edit page" do
            get_step :commitment
            expect(Commitment).to have_received(:new)
          end
        end
      end

      context "when it cannot be set" do
        before do
          allow(policy).to receive(:set_commitment?).and_return(false)
        end

        subject { get_step :commitment }

        it { is_expected.to skip_to_next_step }
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
    let(:policy) { instance_double(ActivityPolicy, update?: true, set_commitment?: true) }

    before do
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

    context "when setting non-ODA on a programme" do
      let(:activity) { programme }

      it "updates the RODA identifier to start with 'NODA'" do
        put_step(:is_oda, {is_oda: false})

        expect(programme.reload.roda_identifier).to start_with("NODA-")
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

    context "when updating a commitment" do
      let(:activity) { programme }

      it "checks whether the user has permission to specifically set the commitment" do
        put_step(:commitment, {commitment: {value: "100"}})

        expect(policy).not_to have_received(:update?)
        expect(policy).to have_received(:set_commitment?)
      end

      context "with valid params" do
        it "allows the user to set the commitment" do
          put_step(:commitment, {commitment: {value: "100"}})

          expect(programme.reload.commitment.value).to eq(100)
        end
      end

      context "with invalid params" do
        it "re-renders the commitment-setting page" do
          expect(put_step(:commitment, {commitment: {value: "INVALID"}})).to render_current_step
        end
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

  def stub_commitment_builder
    allow(Commitment).to receive(:new).and_call_original
  end
end
