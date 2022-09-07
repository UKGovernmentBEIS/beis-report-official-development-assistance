require "rails_helper"

RSpec.describe ActivityHelper, type: :helper do
  let(:organisation) { create(:partner_organisation) }

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
          user = create(:delivery_partner_user)

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
end
