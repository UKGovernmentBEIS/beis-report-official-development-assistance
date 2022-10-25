require "rails_helper"

RSpec.describe ActivityHelper, type: :helper do
  let(:organisation) { create(:partner_organisation) }
  let(:programme_activity) { create(:programme_activity) }
  let(:project_activity) { create(:project_activity) }
  let(:report) { create(:report) }

  describe "#step_is_complete_or_next?" do
    context "when the activity has passed the identification step" do
      it "returns true for the purpose fields" do
        activity = build(:project_activity, :at_purpose_step)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "objectives")).to be(true)
      end

      it "returns false for the next fields following the purpose field" do
        activity = build(:project_activity, :at_identifier_step)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "sector")).to be(false)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "programme_status")).to be(false)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "dates")).to be(false)
        expect(helper.step_is_complete_or_next?(activity: activity, step: "aid_type")).to be(false)
      end
    end

    context "when the activity form has been completed" do
      it "shows all steps" do
        activity = build(:project_activity, form_state: "complete")
        all_steps = Activity::FORM_STEPS

        all_steps.each do |step|
          expect(helper.step_is_complete_or_next?(activity: activity, step: step)).to be(true)
        end
      end
    end
  end

  describe "#link_to_activity_parent" do
    context "when there is no parent" do
      it "returns nil" do
        expect(helper.link_to_activity_parent(parent: nil, user: nil)).to be_nil
      end
    end

    context "when the parent is a fund" do
      context "and the user is partner organisation user" do
        it "returns the parent title without a link" do
          parent_activity = create(:fund_activity)
          _activity = create(:programme_activity, parent: parent_activity)
          user = create(:partner_organisation_user)

          expect(helper.link_to_activity_parent(parent: parent_activity, user: user)).to eql parent_activity.title
        end
      end
    end

    context "when there is a parent" do
      it "returns a link to the parent" do
        parent_activity = create(:fund_activity)
        _activity = create(:programme_activity, parent: parent_activity)
        user = create(:beis_user)

        expect(helper.link_to_activity_parent(parent: parent_activity, user: user)).to include organisation_activity_path(parent_activity.organisation, parent_activity)
        expect(helper.link_to_activity_parent(parent: parent_activity, user: user)).to include parent_activity.title
      end
    end
  end

  describe "#show_link_to_add_comment?" do
    context "when activity is a programme" do
      context "when user is authorised to add programme comments" do
        before { authorise_creating_comments(commentable_type: :programme_activity, authorise: true) }

        it "returns true" do
          expect(helper.show_link_to_add_comment?(activity: programme_activity, report: nil)).to eq(true)
        end
      end

      context "when user is unauthorised to add programme comments" do
        before do
          authorise_creating_comments(commentable_type: :programme_activity, authorise: false)
          authorise_creating_comments(commentable_type: :project_activity, authorise: true)
        end

        it "returns false" do
          expect(helper.show_link_to_add_comment?(activity: programme_activity, report: nil)).to eq(false)
        end
      end
    end

    context "when activity is a project" do
      context "when user is authorised to add project comments" do
        before do
          authorise_creating_comments(commentable_type: :programme_activity, authorise: false)
          authorise_creating_comments(commentable_type: :project_activity, authorise: true)
        end

        context "when a report exists" do
          it "returns true" do
            expect(helper.show_link_to_add_comment?(activity: project_activity, report: report)).to eq(true)
          end
        end

        context "when a report does not exist" do
          it "returns false" do
            expect(helper.show_link_to_add_comment?(activity: project_activity, report: nil)).to eq(false)
          end
        end
      end

      context "when user is unauthorised to add project comments" do
        before do
          authorise_creating_comments(commentable_type: :programme_activity, authorise: false)
          authorise_creating_comments(commentable_type: :project_activity, authorise: false)
        end

        context "when a report exists" do
          it "returns false" do
            expect(helper.show_link_to_add_comment?(activity: project_activity, report: report)).to eq(false)
          end
        end

        context "when a report does not exist" do
          it "returns false" do
            expect(helper.show_link_to_add_comment?(activity: project_activity, report: nil)).to eq(false)
          end
        end
      end
    end
  end

  describe "#show_link_to_edit_comment?" do
    context "when commentable is a programme activity" do
      let(:existing_programme_activity_comment) { create(:comment, commentable: programme_activity, owner: create(:beis_user)) }

      context "when user is authorised to edit programme comments" do
        it "returns true" do
          authorise_updating_comments(commentable_type: :programme_activity, authorise: true)

          expect(helper.show_link_to_edit_comment?(comment: existing_programme_activity_comment)).to eq(true)
        end
      end

      context "when user is unauthorised to add programme comments" do
        it "returns false" do
          authorise_updating_comments(commentable_type: :programme_activity, authorise: false)

          expect(helper.show_link_to_edit_comment?(comment: existing_programme_activity_comment)).to eq(false)
        end
      end
    end

    context "when commentable is a project activity" do
      let(:existing_project_activity_comment) { create(:comment, commentable: project_activity, owner: create(:partner_organisation_user), report: report) }

      context "when user is authorised to add project comments" do
        it "returns true" do
          authorise_updating_comments(commentable_type: :project_activity, authorise: true)

          expect(helper.show_link_to_edit_comment?(comment: existing_project_activity_comment)).to eq(true)
        end
      end

      context "when user is unauthorised to add project comments" do
        it "returns false" do
          authorise_updating_comments(commentable_type: :project_activity, authorise: false)

          expect(helper.show_link_to_edit_comment?(comment: existing_project_activity_comment)).to eq(false)
        end
      end
    end

    context "when commentable is not an activity" do
      let(:actual) { create(:actual, parent_activity: project_activity) }
      let(:existing_actual_comment) { create(:comment, commentable: actual, report: report) }

      context "when user is authorised to add non-activity comments" do
        it "returns true" do
          authorise_updating_comments(commentable_type: :non_activity, authorise: true)

          expect(helper.show_link_to_edit_comment?(comment: existing_actual_comment)).to eq(true)
        end
      end

      context "when user is unauthorised to add non-activity comments" do
        it "returns false" do
          authorise_updating_comments(commentable_type: :non_activity, authorise: false)

          expect(helper.show_link_to_edit_comment?(comment: existing_actual_comment)).to eq(false)
        end
      end
    end
  end

  describe "#custom_capitalisation" do
    context "when a string needs to be presented with the first letter of the first word upcased" do
      it "takes that string, upcases that letter and leaves the rest of the string as it is" do
        sample_string = "programme (level B)"
        expect(custom_capitalisation(sample_string)).to eql("Programme (level B)")
      end
    end
  end

  describe "#benefitting_countries_with_percentages" do
    it "returns an array of structs with country name, code and percentage" do
      codes = ["AG", "LC"]
      countries = benefitting_countries_with_percentages(codes)

      expect(countries.count).to eql(2)

      expect(countries.first.code).to eq("AG")
      expect(countries.first.name).to eq("Antigua and Barbuda")
      expect(countries.first.percentage).to eq(50.0)

      expect(countries.last.code).to eq("LC")
      expect(countries.last.name).to eq("Saint Lucia")
      expect(countries.last.percentage).to eq(50.0)
    end

    it "handles the case when all countries are selected" do
      codes = Codelist.new(type: "benefitting_countries", source: "beis").map { |c| c["code"] }
      countries = benefitting_countries_with_percentages(codes)

      expect(countries.first.percentage).to eq 100 / countries.count.to_f
      expect(countries.last.percentage).to eq 100 / countries.count.to_f
    end

    it "handles the case when three coutries are selected" do
      codes = ["AG", "LC", "BZ"]
      countries = benefitting_countries_with_percentages(codes)

      expect(countries.first.percentage).to eq 100 / countries.count.to_f
      expect(countries.last.percentage).to eq 100 / countries.count.to_f
    end

    it "returns an empty array if the codes are nil or empty" do
      expect(benefitting_countries_with_percentages(nil)).to eq([])
      expect(benefitting_countries_with_percentages([])).to eq([])
    end
  end

  describe "#edit_comment_path_for" do
    let(:activity) { create(:project_activity) }
    let(:comment) { create(:comment, commentable: commentable) }

    context "when the comment is on an activity" do
      let(:commentable) { activity }

      it "generates a link to edit the comment" do
        expect(helper.edit_comment_path_for(commentable, comment)).to eql(edit_activity_comment_path(commentable, comment))
      end
    end

    context "when the comment is on an actual" do
      let(:commentable) { create(:actual, parent_activity: activity) }

      it "generates a link to edit the actual" do
        expect(helper.edit_comment_path_for(commentable, comment)).to eql(edit_activity_actual_path(activity, commentable))
      end
    end
  end

  describe "#can_download_as_xml?" do
    let(:user) { double(:user) }

    context "when the activity is a project" do
      let(:activity) { build(:project_activity) }

      context "when the user can download projects" do
        before { allow_any_instance_of(ProjectPolicy).to receive(:download?).and_return(true) }

        it "returns true" do
          expect(can_download_as_xml?(activity: activity, user: user)).to eql(true)
        end
      end

      context "when the user cannot download projects" do
        before { allow_any_instance_of(ProjectPolicy).to receive(:download?).and_return(false) }

        it "returns false" do
          expect(can_download_as_xml?(activity: activity, user: user)).to eql(false)
        end
      end
    end

    context "when the activity is a third-party project" do
      let(:activity) { build(:third_party_project_activity) }

      context "when the user can download third-party projects" do
        before { allow_any_instance_of(ThirdPartyProjectPolicy).to receive(:download?).and_return(true) }

        it "returns true" do
          expect(can_download_as_xml?(activity: activity, user: user)).to eql(true)
        end
      end

      context "when the user cannot download third-party projects" do
        before { allow_any_instance_of(ThirdPartyProjectPolicy).to receive(:download?).and_return(false) }

        it "returns false" do
          expect(can_download_as_xml?(activity: activity, user: user)).to eql(false)
        end
      end
    end

    context "when the activity is a fund" do
      let(:activity) { build(:fund_activity) }

      it "returns false" do
        expect(can_download_as_xml?(activity: activity, user: user)).to eql(false)
      end
    end

    context "when the activity is a programme" do
      let(:activity) { build(:programme_activity) }

      it "returns false" do
        expect(can_download_as_xml?(activity: activity, user: user)).to eql(false)
      end
    end
  end

  def authorise_creating_comments(commentable_type:, authorise: true)
    without_partial_double_verification do
      case commentable_type
      when :programme_activity
        allow(view).to receive(:policy).with(:level_b).and_return(double(:level_b_policy, create_activity_comment?: authorise))
      when :project_activity
        allow(view).to receive(:policy).with([:activity, :comment]).and_return(double(:activity_policy, create?: authorise))
      end
    end
  end

  def authorise_updating_comments(commentable_type:, authorise: true)
    without_partial_double_verification do
      case commentable_type
      when :programme_activity
        allow(view)
          .to receive(:policy)
          .with(:level_b)
          .and_return(double(:level_b_policy, update_activity_comment?: authorise))
      when :project_activity
        allow(view)
          .to receive(:policy)
          .with(array_including(instance_of(Activity), instance_of(Comment)))
          .and_return(double(:activity_policy, update?: authorise))
      when :non_activity
        allow(view)
          .to receive(:policy)
          .with(array_including(anything, instance_of(Comment)))
          .and_return(double(:activity_policy, update?: authorise))
      end
    end
  end
end
