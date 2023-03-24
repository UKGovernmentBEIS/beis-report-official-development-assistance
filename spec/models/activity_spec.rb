require "rails_helper"

RSpec.describe Activity, type: :model do
  include CodelistHelper, FormHelper, ActivityHelper

  describe "#strip_control_characters_from_fields!" do
    context "for text fields" do
      it "removes control characters and preserves text" do
        activity = Activity.new
        activity.objectives = "kit\x02t\x00en ✓"
        activity.valid?
        expect(activity.objectives).to eq "kitten ✓"
      end
    end

    context "for string fields" do
      it "removes control characters and preserves text" do
        activity = Activity.new
        activity.title = "kit\x02t\x00en ✓"
        activity.valid?
        expect(activity.title).to eq "kitten ✓"
      end
    end
  end

  describe "#finance" do
    let(:activity) { Activity.new }

    subject { activity.finance }

    it "returns Standard Grant, code '110'" do
      expect(subject).to eq "110"
    end

    context "when non-ODA" do
      before { activity.is_oda = false }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end

  describe "#tied_status" do
    let(:activity) { Activity.new }

    subject { activity.tied_status }

    it "returns Untied, code '5'" do
      expect(subject).to eq "5"
    end

    context "when non-ODA" do
      before { activity.is_oda = false }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end

  describe "#capital_spend" do
    it "always returns 0" do
      activity = Activity.new
      expect(activity.capital_spend).to eq 0
    end
  end

  describe "#flow" do
    let(:activity) { Activity.new }

    subject { activity.flow }

    it "returns the default ODA flow type, code '10'" do
      expect(subject).to eq "10"
    end

    context "when non-ODA" do
      before { activity.is_oda = false }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end

  describe ".new_child" do
    let(:parent_activity) { create(:fund_activity, :newton) }
    let(:partner_organisation) { create(:partner_organisation) }

    before do
      allow_any_instance_of(ActivityDefaults).to receive(:call).and_return(
        title: "a returned value",
        form_state: "form_state",
        originating_report_id: "fda36c93-794b-4cc4-b15c-2817f00c7c25"
      )
    end

    it "initialises a new activity with the attribute hash from ActivityDefaults" do
      activity = Activity.new_child(
        parent_activity: parent_activity,
        partner_organisation: partner_organisation
      )

      expect(activity).to be_an_instance_of(Activity)
      expect(activity.title).to eq "a returned value"
      expect(activity.form_state).to eq "form_state"
      expect(activity.originating_report_id).to eq "fda36c93-794b-4cc4-b15c-2817f00c7c25"
    end

    it "accepts a block that can override any default values" do
      parent_activity = create(:fund_activity, :newton)
      partner_organisation = create(:partner_organisation)

      activity = Activity.new_child(
        parent_activity: parent_activity,
        partner_organisation: partner_organisation
      ) { |a|
        a.form_state = "overridden"
      }

      expect(activity.form_state).to eq "overridden"
    end
  end

  describe "scopes" do
    describe ".programmes" do
      it "only returns programme level activities" do
        programme_activity = create(:programme_activity)
        other_activiy = create(:fund_activity)

        expect(Activity.programmes).to include(programme_activity)
        expect(Activity.programmes).not_to include(other_activiy)
      end
    end

    describe ".publishable_to_iati" do
      it "only returns activities where form_state is 'complete' and `publish_to_iati` is true" do
        complete_activity = create(:fund_activity)
        _incomplete_activity = create(:fund_activity, :at_purpose_step)
        _complete_redacted_activity = create(:fund_activity, publish_to_iati: false)
        _incomplete_redacted_activity = create(:fund_activity, :at_identifier_step, publish_to_iati: false)

        expect(Activity.publishable_to_iati).to eq [complete_activity]
      end
    end

    describe ".reportable" do
      it "does not return any unreportable activities" do
        completed_project = create(:project_activity, programme_status: "completed")
        paused_project = create(:project_activity, programme_status: "paused")
        ineligible_project = create(:project_activity, oda_eligibility: "never_eligible")

        eligible_project = create(:project_activity, oda_eligibility: "eligible")
        project_in_delivery = create(:project_activity, programme_status: "delivery")
        project_spend_in_progress = create(:project_activity, programme_status: "spend_in_progress")

        reportable_activities = Activity.reportable

        expect(reportable_activities).to include(eligible_project)
        expect(reportable_activities).to include(project_in_delivery)
        expect(reportable_activities).to include(project_spend_in_progress)

        expect(reportable_activities).to_not include(completed_project)
        expect(reportable_activities).to_not include(paused_project)
        expect(reportable_activities).to_not include(ineligible_project)
      end
    end
  end

  describe "sanitisation" do
    it { should strip_attribute(:partner_organisation_identifier) }
  end

  describe "callbacks" do
    describe "#set_non_oda_defaults" do
      let(:activity) { create(:programme_activity, :ispf_funded) }

      context "when is_oda has changed to false" do
        before do
          activity.is_oda = false
          activity.save
        end

        it "sets ODA only attributes to nil" do
          expect(activity.transparency_identifier).to be_nil
          expect(activity.oda_eligibility).to be_nil
          expect(activity.fstc_applies).to be_nil
          expect(activity.covid19_related).to be_nil
          expect(activity.policy_marker_gender).to be_nil
          expect(activity.policy_marker_climate_change_adaptation).to be_nil
          expect(activity.policy_marker_climate_change_mitigation).to be_nil
          expect(activity.policy_marker_biodiversity).to be_nil
          expect(activity.policy_marker_desertification).to be_nil
          expect(activity.policy_marker_disability).to be_nil
          expect(activity.policy_marker_disaster_risk_reduction).to be_nil
          expect(activity.policy_marker_nutrition).to be_nil
        end

        it "sets publish_to_iati to false" do
          expect(activity.publish_to_iati).to be(false)
        end
      end
    end
  end

  describe "validations" do
    it { should validate_attribute(:planned_start_date).with(:date_within_boundaries) }
    it { should validate_attribute(:planned_end_date).with(:date_within_boundaries) }
    it { should validate_attribute(:actual_start_date).with(:date_within_boundaries) }
    it { should validate_attribute(:actual_end_date).with(:date_within_boundaries) }

    context "overall activity state" do
      context "when the activity form is final" do
        subject { build(:project_activity, :at_identifier_step, form_state: "complete") }
        it { should be_invalid }
      end
    end

    context "#form_state" do
      context "when the form_state is set to a value we expect" do
        subject(:activity) { build(:project_activity) }
        it "should be valid" do
          expect(activity.valid?).to be_truthy
        end
      end

      context "when form_state is set to a value not included in the validation list" do
        subject(:activity) { build(:project_activity, form_state: "completed") }
        it "should not be valid" do
          expect(activity.valid?).to be_falsey
        end
      end

      context "when form_state is set to a value included in the validation list" do
        subject(:activity) { build(:project_activity, form_state: "purpose") }
        it "should be valid" do
          expect(activity.valid?).to be_truthy
        end
      end
    end

    context "when partner_organisation_identifier is blank" do
      subject(:activity) { build(:project_activity, partner_organisation_identifier: nil) }
      it "should not be valid" do
        expect(activity.valid?(:identifier_step)).to be_falsey
      end
    end

    describe "#partner_organisation_identifier" do
      context "when an activity exists with the same partner_organisation_identifier" do
        context "shares the same parent" do
          it "should be invalid" do
            fund = create(:fund_activity)
            create(:programme_activity, partner_organisation_identifier: "GB-GOV-13-001", parent: fund)

            new_programme_activity = build(:programme_activity, partner_organisation_identifier: "GB-GOV-13-001", parent: fund)

            expect(new_programme_activity).not_to be_valid
          end
        end

        context "does NOT share the same parent" do
          it "should be valid" do
            create(:fund_activity) do |fund|
              create(:programme_activity, partner_organisation_identifier: "GB-GOV-13-001", parent: fund)
            end

            other_fund = create(:fund_activity)
            new_programme_activity = build(:programme_activity, partner_organisation_identifier: "GB-GOV-13-001", parent: other_fund)

            expect(new_programme_activity).to be_valid
          end
        end
      end
    end

    context "when title is blank" do
      subject(:activity) { build(:project_activity, title: nil) }
      it "should not be valid" do
        expect(activity.valid?(:purpose_step)).to be_falsey
      end
    end

    context "when description is blank" do
      subject(:activity) { build(:project_activity, description: nil) }
      it "should not be valid" do
        expect(activity.valid?(:purpose_step)).to be_falsey
      end
    end

    context "when objectives is blank" do
      subject(:activity) { build(:programme_activity, objectives: nil) }
      it "should not be valid" do
        expect(activity.valid?(:objectives_step)).to be_falsey
      end
    end

    context "when sector category is blank" do
      subject(:activity) { build(:project_activity, sector_category: nil) }
      it "should not be valid" do
        expect(activity.valid?(:sector_category_step)).to be_falsey
      end
    end

    context "when sector is blank" do
      subject(:activity) { build(:project_activity, sector: nil) }
      it "should not be valid" do
        expect(activity.valid?(:sector_step)).to be_falsey
      end
    end

    context "when planned start and actual start dates are blank" do
      subject(:activity) { build(:project_activity, planned_start_date: nil, actual_start_date: nil) }
      it "should not be valid" do
        expect(activity.valid?(:dates_step)).to be_falsey
      end
    end

    context "when programme status is blank" do
      subject(:activity) { build(:project_activity, programme_status: nil) }
      it "should not be valid" do
        expect(activity.valid?(:programme_status_step)).to be_falsey
      end
    end

    context "when planned_start_date is blank but actual_start_date is not nil" do
      subject(:activity) { build(:project_activity, planned_start_date: nil) }
      it "should be valid" do
        expect(activity.valid?(:dates_step)).to be_truthy
      end
    end

    context "when actual_start_date is blank but planned_start_date is not nil" do
      subject(:activity) { build(:project_activity, actual_start_date: nil) }
      it "should be valid" do
        expect(activity.valid?(:dates_step)).to be_truthy
      end
    end

    context "when planned_end_date is blank" do
      subject(:activity) { build(:project_activity, planned_end_date: nil) }
      it "should be valid" do
        expect(activity.valid?(:dates_step)).to be_truthy
      end
    end

    context "when actual_start_date is blank" do
      subject(:activity) { build(:project_activity, actual_start_date: nil) }
      it "should be valid" do
        expect(activity.valid?(:dates_step)).to be_truthy
      end
    end

    context "when actual_end_date is blank" do
      subject(:activity) { build(:project_activity, actual_end_date: nil) }
      it "should be valid" do
        expect(activity.valid?(:dates_step)).to be_truthy
      end
    end

    context "when planned_end_date is not blank" do
      let(:activity) { build(:project_activity) }

      it "does not allow planned_end_date to be earlier than planned_start_date" do
        activity = build(:project_activity, planned_start_date: Date.today, planned_end_date: Date.yesterday)
        expect(activity.valid?).to be_falsey
        expect(activity.errors[:planned_end_date]).to include "Planned end date must be after planned start date"
      end
    end

    context "when country_partner_organisations is blank/empty array on a Newton funded programme" do
      subject(:newton_fund) { build(:fund_activity, :newton) }
      subject(:activity) { build(:programme_activity, parent: newton_fund, country_partner_organisations: nil) }
      it "should not be valid" do
        expect(activity.valid?(:country_partner_organisations_step)).to be_falsey
      end
    end

    context "when country_partner_organisations is blank on a Newton funded project" do
      subject(:newton_fund) { build(:fund_activity, :newton) }
      subject(:newton_programme) { build(:programme_activity, parent: newton_fund) }
      subject(:activity) { build(:project_activity, parent: newton_programme, country_partner_organisations: nil) }
      it "should be valid" do
        expect(activity.valid?).to be_truthy
      end
    end

    context "when country_partner_organisations is blank on a non-Newton funded programme" do
      subject(:activity) { build(:programme_activity, :gcrf_funded, country_partner_organisations: nil) }
      it "should be valid" do
        expect(activity.valid?).to be_truthy
      end
    end

    context "when gdi is blank" do
      subject(:activity) { build(:project_activity, gdi: nil) }
      it "should not be valid" do
        expect(activity.valid?(:gdi_step)).to be_falsey
      end
    end

    context "#fund_pillar" do
      it "is required if the activity is a Newton-funded programme activity" do
        activity = build(:programme_activity, :newton_funded, fund_pillar: nil)

        expect(activity.valid?(:fund_pillar_step)).to be_falsey
      end

      it "is not required if the activity is a GCRF-funded programme activity" do
        activity = build(:programme_activity, :gcrf_funded, fund_pillar: nil)

        expect(activity.valid?(:fund_pillar_step)).to be_truthy
      end

      it "is required if the activity is a Newton-funded project activity" do
        activity = build(:project_activity, :newton_funded, fund_pillar: nil)

        expect(activity.valid?(:fund_pillar_step)).to be_falsey
      end

      it "is not required if the activity is a GCRF-funded third party project activity" do
        activity = build(:third_party_project_activity, :gcrf_funded, fund_pillar: nil)

        expect(activity.valid?(:fund_pillar_step)).to be_truthy
      end

      it "is required if the activity is a Newton-funded third party project activity" do
        activity = build(:third_party_project_activity, :newton_funded, fund_pillar: nil)

        expect(activity.valid?(:fund_pillar_step)).to be_falsey
      end

      it "is not required if the activity is a GCRF-funded project activity" do
        activity = build(:project_activity, :gcrf_funded, fund_pillar: nil)

        expect(activity.valid?(:fund_pillar_step)).to be_truthy
      end

      it "is not required if the activity is a fund" do
        activity = build(:fund_activity, fund_pillar: nil)

        expect(activity.valid?(:fund_pillar_step)).to be_truthy
      end
    end

    context "#sdg_1" do
      it "is required if sdgs_apply is true" do
        activity = build(:programme_activity, sdgs_apply: true)

        expect(activity.valid?(:sustainable_development_goals_step)).to be_falsey
      end

      it "is not required if sdgs_apply is false" do
        activity = build(:programme_activity, sdgs_apply: false)

        expect(activity.valid?(:sustainable_development_goals_step)).to be_truthy
      end
    end

    context "when fstc applies is blank" do
      subject(:activity) { build(:project_activity, fstc_applies: nil) }
      it "should not be valid" do
        expect(activity.valid?(:fstc_applies_step)).to be_falsey
      end
    end

    context "when Covid19-related research is blank" do
      subject(:activity) { build(:project_activity, covid19_related: nil) }
      it "should not be valid" do
        expect(activity.valid?(:covid19_related_step)).to be_falsey
      end
    end

    context "when activity is a fund and collaboration_type is blank" do
      subject(:activity) { build(:fund_activity, collaboration_type: nil) }
      it "should be valid" do
        expect(activity.valid?(:collaboration_type_step)).to be_truthy
      end
    end

    context "when any of the policy markers is blank on levels C or D" do
      subject(:activity) { build(:project_activity, policy_marker_gender: nil) }
      it "should not be valid" do
        expect(activity.valid?(:policy_markers_step)).to be_falsey
      end
    end

    context "when gcrf_strategic_area is blank" do
      let(:source_fund_code) { Fund.by_short_name("NF").id }
      subject { build(:programme_activity, source_fund_code: source_fund_code, gcrf_strategic_area: nil) }

      it { is_expected.to be_valid(:gcrf_strategic_area_step) }

      context "with a GCRF funded activity" do
        let(:source_fund_code) { Fund.by_short_name("GCRF").id }

        it { is_expected.to be_invalid(:gcrf_strategic_area_step) }
      end

      context "for a fund" do
        subject { build(:fund_activity, :gcrf, gcrf_strategic_area: nil) }

        it { is_expected.to be_valid(:gcrf_strategic_area_step) }
      end
    end

    context "when gcrf_strategic_area has too many values" do
      let(:source_fund_code) { Fund.by_short_name("NF").id }
      let(:strategic_areas) { %w[RF CIm IP] }
      subject { build(:programme_activity, source_fund_code: source_fund_code, gcrf_strategic_area: strategic_areas) }

      context "with a GCRF funded activity" do
        let(:source_fund_code) { Fund.by_short_name("GCRF").id }

        it { is_expected.to be_invalid(:gcrf_strategic_area_step) }
      end
    end

    context "when gcrf_challenge_area is blank" do
      let(:source_fund_code) { Fund.by_short_name("NF").id }
      subject { build(:programme_activity, source_fund_code: source_fund_code, gcrf_challenge_area: nil) }

      it { is_expected.to be_valid(:gcrf_challenge_area_step) }
      it { is_expected.to be_valid }

      context "with a GCRF funded activity" do
        let(:source_fund_code) { Fund.by_short_name("GCRF").id }

        it { is_expected.to be_invalid(:gcrf_challenge_area_step) }
        it { is_expected.to be_invalid }
      end

      context "for a fund" do
        subject { build(:fund_activity, :gcrf, gcrf_challenge_area: nil) }

        it { is_expected.to be_valid(:gcrf_challenge_area_step) }
        it { is_expected.to be_valid }
      end
    end

    context "when oda_eligibility is blank" do
      subject(:activity) { build(:project_activity, oda_eligibility: nil) }
      it "should not be valid" do
        expect(activity.valid?(:oda_eligibility_step)).to be_falsey
      end
    end

    context "when oda_eligibility is an invalid text string" do
      subject(:activity) { build(:project_activity, oda_eligibility: "kitten") }

      it "should raise an error" do
        expect { activity }.to raise_error("'kitten' is not a valid oda_eligibility")
      end
    end

    context "when saving in the oda_eligibility_lead_step context" do
      context "and the activity is a fund" do
        subject { build(:project_activity, level: :fund) }
        it { should_not validate_presence_of(:oda_eligibility_lead).on(:oda_eligibility_lead_step) }
      end

      context "and the activity is a programme" do
        subject { build(:project_activity, level: :programme) }
        it { should_not validate_presence_of(:oda_eligibility_lead).on(:oda_eligibility_lead_step) }
      end

      context "and the activity is a project" do
        subject { build(:project_activity, level: :project) }
        it { should validate_presence_of(:oda_eligibility_lead).on(:oda_eligibility_lead_step) }
      end

      context "and the activity is a third party project" do
        subject { build(:project_activity, level: :third_party_project) }
        it { should validate_presence_of(:oda_eligibility_lead).on(:oda_eligibility_lead_step) }
      end
    end

    context "when saving in the uk_po_named_contact context" do
      context "and the activity is a fund" do
        subject { build(:project_activity, level: :fund) }
        it { should_not validate_presence_of(:uk_po_named_contact).on(:uk_po_named_contact_step) }
      end

      context "and the activity is a programme" do
        subject { build(:project_activity, level: :programme) }
        it { should_not validate_presence_of(:uk_po_named_contact).on(:uk_po_named_contact_step) }
      end

      context "when the activity is a project" do
        subject { build(:project_activity) }
        it { should validate_presence_of(:uk_po_named_contact).on(:uk_po_named_contact_step) }
      end

      context "when the activity is a third party project" do
        subject { build(:third_party_project_activity) }
        it { should validate_presence_of(:uk_po_named_contact).on(:uk_po_named_contact_step) }
      end
    end

    context "when the activity is neither a fund nor a programme" do
      context "when call_present is blank" do
        subject(:activity) { build(:project_activity, call_present: nil) }
        it "should not be valid" do
          expect(activity.valid?(:call_present_step)).to be_falsey
        end
      end

      context "when there is a call but any of the call dates are blank" do
        subject(:activity) { build(:project_activity, call_present: true, call_open_date: Date.today, call_close_date: nil) }
        it "should not be valid" do
          expect(activity.valid?(:call_dates_step)).to be_falsey
        end
      end

      context "when there is a call and total applications is blank" do
        subject(:activity) { build(:project_activity, call_present: true, total_applications: nil) }
        it "should not be valid" do
          expect(activity.valid?(:total_applications_and_awards_step)).to be_falsey
        end
      end

      context "when there is a call and total awards is blank" do
        subject(:activity) { build(:project_activity, call_present: true, total_awards: nil) }
        it "should not be valid" do
          expect(activity.valid?(:total_applications_and_awards_step)).to be_falsey
        end
      end
    end

    describe "channel_of_delivery_code" do
      it "is not required for a fund" do
        expect(build(:fund_activity, channel_of_delivery_code: nil)).to be_valid
      end

      it "is not required for a programme" do
        expect(build(:programme_activity, channel_of_delivery_code: nil)).to be_valid
      end

      it "is required to be a BEIS-allowed code for a project" do
        activity = build(:project_activity, channel_of_delivery_code: nil)
        expect(activity).to be_invalid

        activity.channel_of_delivery_code = "62009"
        expect(activity).to be_invalid

        activity.channel_of_delivery_code = "11000"
        expect(activity).to be_valid
      end

      it "is required to be a BEIS-allowed code for a third party project" do
        activity = build(:third_party_project_activity, channel_of_delivery_code: nil)
        expect(activity).to be_invalid

        activity.channel_of_delivery_code = "62009"
        expect(activity).to be_invalid

        activity.channel_of_delivery_code = "11000"
        expect(activity).to be_valid
      end
    end

    describe "parent association" do
      let(:organisation) { build(:partner_organisation) }
      subject { Activity.new(level: level, organisation: organisation) }

      context "with a fund" do
        let(:organisation) { build(:beis_organisation) }
        let(:level) { "fund" }

        it { is_expected.to validate_absence_of :parent }
        it { is_expected.to_not validate_presence_of :parent }
      end

      context "with a programme" do
        let(:level) { "programme" }

        it { is_expected.to validate_presence_of :parent }
        it { is_expected.to_not validate_absence_of :parent }
      end

      context "with a project" do
        let(:level) { "project" }

        it { is_expected.to validate_presence_of :parent }
        it { is_expected.to_not validate_absence_of :parent }
      end

      context "with a third-party project" do
        let(:level) { "third_party_project" }

        it { is_expected.to validate_presence_of :parent }
        it { is_expected.to_not validate_absence_of :parent }
      end
    end

    context "for an ISPF ODA activity" do
      let(:activity) { build(:programme_activity, :ispf_funded, is_oda: true) }

      context "when the None option is chosen for ISPF ODA partner countries" do
        it "validates that no other countries are selected" do
          activity.ispf_oda_partner_countries = ["IN", "NONE"]

          expect(activity.valid?).to be(false)
          expect(activity.errors[:ispf_oda_partner_countries].first).to eq(t("activerecord.errors.models.activity.attributes.ispf_oda_partner_countries.none_exclusive"))
        end
      end
    end

    context "for an ISPF non-ODA activity" do
      let(:activity) { build(:programme_activity, :ispf_funded, is_oda: false) }

      context "when the None option is chosen for ISPF non-ODA partner countries" do
        it "validates that no other countries are selected" do
          activity.ispf_non_oda_partner_countries = ["IN", "NONE"]

          expect(activity.valid?).to be(false)
          expect(activity.errors[:ispf_non_oda_partner_countries].first).to eq(t("activerecord.errors.models.activity.attributes.ispf_non_oda_partner_countries.none_exclusive"))
        end
      end
    end

    describe "validating commitments on activity creation" do
      context "when the activity has a planned start date" do
        it "validates the commitment" do
          activity = build(:project_activity, planned_start_date: Date.today, actual_start_date: nil)
          activity.build_commitment(value: "invalid!")
          activity.save

          expect(activity.commitment).not_to be_persisted
          expect(activity.errors.full_messages).to include(
            "Original commitment figure Original commitment figure is invalid"
          )
        end
      end

      context "when the activity has an actual start date" do
        it "validates the commitment" do
          activity = build(:project_activity, actual_start_date: Date.today, planned_start_date: nil)
          activity.build_commitment(value: "invalid!")
          activity.save

          expect(activity.commitment).not_to be_persisted
          expect(activity.errors.full_messages).to include(
            "Original commitment figure Original commitment figure is invalid"
          )
        end
      end

      context "when the activity has no planned start or end date" do
        it "does not validate the commitment's transaction date, so as not to display a misleading error in the activity upload errors" do
          activity = build(:project_activity, actual_start_date: nil, planned_start_date: nil)
          activity.build_commitment(value: 1000)
          activity.save

          expect(activity.commitment).not_to be_persisted
          expect(activity.errors.full_messages).not_to include(
            "Original commitment figure Original commitment figure is invalid"
          )
        end
      end
    end

    describe "inclusions" do
      describe "#aid_type" do
        let(:codes) { Codelist.new(type: "aid_type", source: "beis").values_for("code") }

        it { is_expected.to validate_inclusion_of(:aid_type).in_array(codes).on(:aid_type_step) }
      end

      describe "#collaboration_type" do
        let(:codes) { collaboration_type_radio_options.map(&:code) }

        it { is_expected.to validate_inclusion_of(:collaboration_type).in_array(codes).on(:collaboration_type_step) }
      end

      describe "#covid19_related" do
        let(:codes) { Codelist.new(type: "accepted_collaboration_types_and_channel_of_delivery_mapping", source: "beis").values_for("code") }

        it { is_expected.to validate_inclusion_of(:covid19_related).in_array(codes).on(:covid19_related_step) }
      end

      describe "#fund_pillar" do
        context "when Newton funded" do
          let(:codes) { Codelist.new(type: "fund_pillar", source: "beis").values_for("code") }

          subject { build(:programme_activity, :newton_funded) }

          it { is_expected.to validate_inclusion_of(:fund_pillar).in_array(codes).on(:fund_pillar_step) }
        end
      end

      describe "#gcrf_challenge_area" do
        context "when GCRF funded" do
          let(:codes) { Codelist.new(type: "gcrf_challenge_area", source: "beis").values_for("code") }

          subject { build(:programme_activity, :gcrf_funded) }

          it { is_expected.to validate_inclusion_of(:gcrf_challenge_area).in_array(codes).on(:gcrf_challenge_area_step) }
        end
      end

      describe "#gdi" do
        let(:codes) { Codelist.new(type: "gdi").values_for("code") }

        it { is_expected.to validate_inclusion_of(:gdi).in_array(codes).on(:gdi_step) }
      end

      describe "#sector_category" do
        let(:codes) { Codelist.new(type: "sector_category").values_for("code") }

        it { is_expected.to validate_inclusion_of(:sector_category).in_array(codes).on(:sector_category_step) }
      end

      describe "#sector" do
        let(:codes) { Codelist.new(type: "sector").values_for("code") }

        it { is_expected.to validate_inclusion_of(:sector).in_array(codes).on(:sector_step) }
      end

      describe "#ispf_themes" do
        context "when activity is ISPF funded" do
          let(:codes) { Codelist.new(type: "ispf_themes", source: "beis").values_for("code") }

          subject { build(:programme_activity, :ispf_funded) }

          it { is_expected.to validate_inclusion_of(:ispf_themes).in_array(codes).on(:ispf_themes_step) }
        end
      end

      describe "#ispf_oda_partner_countries" do
        context "when activity is ODA" do
          let(:none_code) { "NONE" }
          let(:codes) do
            Codelist.new(type: "ispf_oda_partner_countries", source: "beis")
              .values_for("code")
              .reject { |value| value == none_code }
          end

          subject { build(:programme_activity, :ispf_funded) }

          it { is_expected.to allow_values(codes, [none_code]).for(:ispf_oda_partner_countries).on(:ispf_oda_partner_countries_step) }
          it { is_expected.not_to allow_values(["Wrong"]).for(:ispf_oda_partner_countries).on(:ispf_oda_partner_countries_step) }
        end
      end

      describe "#ispf_non_oda_partner_countries" do
        context "when activity is non-ODA" do
          let(:none_code) { "NONE" }
          let(:codes) do
            Codelist.new(type: "ispf_non_oda_partner_countries", source: "beis")
              .values_for("code")
              .reject { |value| value == none_code }
          end

          subject { build(:programme_activity, :ispf_funded, is_oda: false) }

          it { is_expected.to allow_values(codes, [none_code]).for(:ispf_non_oda_partner_countries).on(:ispf_non_oda_partner_countries_step) }
          it { is_expected.not_to allow_values(["Wrong"]).for(:ispf_non_oda_partner_countries).on(:ispf_non_oda_partner_countries_step) }
        end
      end

      describe "sustainable development goals" do
        let(:applicable_options) { sdg_options.keys.select { |k| k.is_a?(Numeric) } }

        subject { build(:programme_activity, sdgs_apply: true) }

        describe "#sdg_1" do
          it { is_expected.to allow_values(*applicable_options).for(:sdg_1).on(:sustainable_development_goals_step) }
          it { is_expected.not_to allow_values(123456789).for(:sdg_1).on(:sustainable_development_goals_step) }
        end

        describe "#sdg_2" do
          it { is_expected.to allow_values(*applicable_options, nil).for(:sdg_2).on(:sustainable_development_goals_step) }
          it { is_expected.not_to allow_values(123456789).for(:sdg_2).on(:sustainable_development_goals_step) }
        end

        describe "#sdg_3" do
          it { is_expected.to allow_values(*applicable_options, nil).for(:sdg_3).on(:sustainable_development_goals_step) }
          it { is_expected.not_to allow_values(123456789).for(:sdg_2).on(:sustainable_development_goals_step) }
        end
      end

      describe "#benefitting_countries" do
        subject { build(:programme_activity, :ispf_funded, is_oda: true) }

        it { is_expected.to allow_values(*all_benefitting_country_codes).for(:benefitting_countries).on(:benefitting_countries_step) }
        it { is_expected.not_to allow_values(["Wrong"]).for(:benefitting_countries).on(:benefitting_countries_step) }
      end
    end
  end

  describe "associations" do
    it { should belong_to(:originating_report).optional }
    it { should belong_to(:organisation) }
    it { should have_many(:child_activities).with_foreign_key("parent_id") }
    it { should belong_to(:extending_organisation).with_foreign_key("extending_organisation_id").optional }
    it { should have_many(:implementing_organisations) }
    it { should have_many(:implementing_org_participations) }
    it { should have_many(:budgets) }
    it { should have_many(:actuals) }
    it { should have_many(:refunds) }
    it { should have_many(:adjustments) }
    it { should have_many(:source_transfers) }
    it { should have_many(:destination_transfers) }
    it { should have_many(:matched_efforts) }
    it { should have_many(:external_incomes) }
    it { should have_many(:historical_events) }
    it { should have_one(:commitment) }
    it { should have_many(:comments) }

    describe ".comments_on_self_and_transactions" do
      it "fetches comments related to a given activity including comments on its child transactions" do
        activity = create(:project_activity)
        actual = create(:actual, :with_comment, parent_activity: activity)
        refund = create(:refund, parent_activity: activity)
        adjustment = create(:adjustment, parent_activity: activity)

        activity_comment = create(:comment, commentable: activity)

        _comments = create_list(:comment, 5)
        _actuals = create_list(:actual, 2, :with_comment)
        _refunds = create_list(:refund, 2)
        _adjustments = create_list(:adjustment, 2)

        expect(activity.comments_on_self_and_transactions).to match_array([
          activity_comment,
          actual.comment,
          refund.comment,
          adjustment.comment
        ])
      end
    end
  end

  describe "#implementing_org_participations" do
    # for unknown reasons it's not possible to build a new OrgParticiption
    # join entity on an unsaved Activity. i.e.
    #
    #    Activity.new#implementing_organisations << implementing_org
    #
    # does not set OrgParticipation#activity_id when you come to save the
    # new activity. Activity then returns a validation error:
    #
    #    -> Implementing org participations is invalid
    #
    #  This is related to the presence of the condition filtering by
    #  OrgParticipation#role on the Activity has_many :implementing_organisations
    #  method. Without this condition, the Activity#implementing_organisations <<
    #  method works as expected on a new Activity.
    #
    #  NB: this is issue only affect new (unsaved) instances of an Activity.
    #
    # The workaround is to set the OrgParticipation join entity manually,
    # which is much less elegant!
    context "when building a new activity" do
      let(:activity) { build(:programme_activity) }
      let(:implementing_org) { create(:implementing_organisation) }

      it "adds and then saves the expected OrgParticipation join entity" do
        activity.implementing_org_participations << OrgParticipation.new(
          organisation: implementing_org,
          role: "implementing",
          activity: activity
        )

        activity.save!

        expect(activity.reload.implementing_organisations).to eq([implementing_org])
      end
    end
  end

  describe "has_one #latest_report association" do
    let(:activity) do
      create(:project_activity)
    end

    let!(:latest_report) do
      create(
        :report,
        :active,
        organisation: activity.organisation,
        fund: activity.associated_fund,
        financial_quarter: 3,
        financial_year: 2021
      )
    end

    let!(:_earlier_report) do
      create(
        :report,
        :approved,
        organisation: activity.organisation,
        fund: activity.associated_fund,
        financial_quarter: 2,
        financial_year: 2021
      )
    end

    describe "#latest_report" do
      it "returns the most recent report" do
        expect(activity.latest_report).to eq(latest_report)
      end
    end
  end

  describe "#parent_activities" do
    context "when the activity is a fund" do
      it "returns an empty array" do
        result = build(:fund_activity).parent_activities
        expect(result).to eq([])
      end
    end

    context "when the activity is a programme" do
      it "returns the fund" do
        programme = create(:programme_activity)
        fund = programme.parent

        result = programme.parent_activities
        expect(result.first.id).to eq(fund.id)
      end
    end

    context "when the activity is a project" do
      it "returns the fund and then the programme" do
        project = create(:project_activity)
        programme = project.parent
        fund = programme.parent

        result = project.parent_activities

        expect(result.first.id).to eq(fund.id)
        expect(result.second.id).to eq(programme.id)
      end
    end

    context "when the activity is a third party project" do
      it "returns the fund and then the programme and then the project" do
        third_party_project = create(:third_party_project_activity)
        project = third_party_project.parent
        programme = project.parent
        fund = programme.parent

        result = third_party_project.parent_activities

        expect(result.first.id).to eq(fund.id)
        expect(result.second.id).to eq(programme.id)
        expect(result.third.id).to eq(project.id)
      end
    end
  end

  describe "#associated_fund" do
    context "when the activity is a fund" do
      it "returns itself" do
        fund = create(:fund_activity)
        expect(fund.associated_fund).to eq(fund)
      end
    end

    context "when the activity is a programme" do
      it "returns the parent fund" do
        programme = create(:programme_activity)
        fund = programme.parent

        expect(programme.associated_fund).to eq(fund)
      end
    end

    context "when the activity is a project" do
      it "returns the ancestor fund" do
        project = create(:project_activity)
        programme = project.parent
        fund = programme.parent

        expect(project.associated_fund).to eq(fund)
      end
    end

    context "when the activity is a third party project" do
      it "returns the ancestor fund" do
        third_party_project = create(:third_party_project_activity)
        project = third_party_project.parent
        programme = project.parent
        fund = programme.parent

        expect(third_party_project.associated_fund).to eq(fund)
      end
    end
  end

  describe "#form_steps_completed?" do
    it "is true when a user has completed all of the form steps" do
      activity = build(:project_activity, form_state: :complete)

      expect(activity.form_steps_completed?).to be_truthy
    end

    it "is false when a user is still completing one of the form steps" do
      activity = build(:project_activity, form_state: :purpose)

      expect(activity.form_steps_completed?).to be_falsey
    end

    it "is false when the form_state is nil" do
      activity = build(:project_activity, form_state: nil)

      expect(activity.form_steps_completed?).to be_falsey
    end
  end

  describe "#has_extending_organisation?" do
    it "returns true if all extending_organisation fields are present" do
      activity = build(:fund_activity)

      expect(activity.has_extending_organisation?).to be(true)
    end

    it "returns false if all extending_organisation fields are not present" do
      activity = build(:project_activity, extending_organisation: nil)

      expect(activity.has_extending_organisation?).to be(false)
    end
  end

  describe "#has_implementing_organisations?" do
    it "returns true when there is one or more implementing organisations" do
      activity = create(:project_activity_with_implementing_organisations)

      expect(activity.has_implementing_organisations?).to be(true)
    end
  end

  describe "#providing_organisation" do
    context "when the activity is a fund or a programme" do
      it "returns BEIS" do
        beis = create(:beis_organisation)
        fund = build(:fund_activity)
        expect(fund.providing_organisation).to eql beis

        programme = build(:programme_activity)
        expect(programme.providing_organisation).to eql beis
      end
    end

    context "when the activity is a project" do
      context "when the activity organisation is a government type" do
        it "returns BEIS" do
          beis = create(:beis_organisation)
          government_partner_org = build(:partner_organisation, organisation_type: "10")

          project = build(:project_activity, organisation: government_partner_org)
          expect(project.providing_organisation).to eql beis
        end
      end

      context "when the activity organisation is a non-government type" do
        it "returns BEIS" do
          beis = create(:beis_organisation)
          non_government_partner_org = create(:partner_organisation, organisation_type: "22")

          project = build(:project_activity, organisation: non_government_partner_org)
          expect(project.providing_organisation).to eql beis
        end
      end
    end

    context "when the activity is a third-party project" do
      context "when the activity organisation is a government type" do
        it "returns BEIS" do
          beis = create(:beis_organisation)
          government_partner_org = build(:partner_organisation, organisation_type: "10")

          project = build(:project_activity, organisation: government_partner_org)
          expect(project.providing_organisation).to eql beis
        end
      end

      context "when the activity organisation is a non-government type" do
        it "returns the activity organisation i.e the partner organisation" do
          non_government_partner_org = create(:partner_organisation, organisation_type: "22")

          third_party_project = build(:third_party_project_activity, organisation: non_government_partner_org)
          expect(third_party_project.providing_organisation).to eql non_government_partner_org
        end
      end
    end
  end

  describe "#funding_organisation" do
    let!(:beis) { create(:beis_organisation) }

    it "returns BEIS if the activity is a programme" do
      project = build(:programme_activity)
      expect(project.funding_organisation).to eql beis
    end

    it "returns BEIS if the activity is a project" do
      project = build(:project_activity)
      expect(project.funding_organisation).to eql beis
    end

    it "returns BEIS if the activity is a third party project" do
      project = build(:third_party_project_activity)
      expect(project.funding_organisation).to eql beis
    end

    it "returns nil if the activity is a fund" do
      fund = build(:fund_activity)
      expect(fund.funding_organisation).to be_nil
    end
  end

  describe "#accountable_organisation" do
    let(:beis) { build_stubbed(:beis_organisation) }
    let(:partner_organisation) { build_stubbed(:partner_organisation) }

    before do
      allow_any_instance_of(Activity).to receive(:service_owner).and_return(beis)
    end

    it "returns BEIS if the activity is a fund" do
      activity = build_stubbed(:fund_activity)
      expect(activity.accountable_organisation).to eql beis
    end

    it "returns BEIS if the activity is a programme" do
      activity = build_stubbed(:programme_activity, extending_organisation: partner_organisation)
      expect(activity.accountable_organisation).to eql beis
    end

    it "returns BEIS if the activity is a project" do
      activity = build_stubbed(:project_activity, extending_organisation: partner_organisation)
      expect(activity.accountable_organisation).to eql beis
    end

    it "returns BEIS if the activity is a third-party project" do
      activity = build_stubbed(:third_party_project_activity, extending_organisation: partner_organisation)
      expect(activity.accountable_organisation).to eql beis
    end

    context "with a non-government partner organisation" do
      let(:partner_organisation) { build_stubbed(:partner_organisation, :non_government) }

      it "returns the partner organisation if the activity is a project" do
        activity = build_stubbed(:project_activity, extending_organisation: partner_organisation)
        expect(activity.accountable_organisation).to eql partner_organisation
      end

      it "returns the partner organisation if the activity is a third-party project" do
        activity = build_stubbed(:third_party_project_activity, extending_organisation: partner_organisation)
        expect(activity.accountable_organisation).to eql partner_organisation
      end
    end
  end

  describe "accountable_organisation_* getters" do
    let(:beis) { build_stubbed(:beis_organisation) }
    let(:partner_organisation) { build_stubbed(:partner_organisation, :non_government) }
    let(:activity) { build_stubbed(:project_activity, extending_organisation: partner_organisation) }

    before do
      allow_any_instance_of(Activity).to receive(:service_owner).and_return(beis)
    end

    describe "#accountable_organisation_name" do
      it "delegates to accountable_organisation.name" do
        expect(activity.accountable_organisation_name).to eql activity.accountable_organisation.name
      end
    end

    describe "#accountable_organisation_name" do
      it "delegates to accountable_organisation.organisation_type" do
        expect(activity.accountable_organisation_type).to eql activity.accountable_organisation.organisation_type
      end
    end

    describe "#accountable_organisation_reference" do
      it "delegates to accountable_organisation.iati_reference" do
        expect(activity.accountable_organisation_reference).to eql activity.accountable_organisation.iati_reference
      end
    end
  end

  describe "#parent_level" do
    context "when the level is a fund" do
      it "returns nil" do
        result = described_class.new(level: :fund).parent_level
        expect(result).to eql(nil)
      end
    end

    context "when the level is a programme" do
      it "returns a string for fund" do
        result = described_class.new(level: :programme).parent_level
        expect(result).to eql("fund")
      end
    end

    context "when the level is a project" do
      it "returns a string for programme" do
        result = described_class.new(level: :project).parent_level
        expect(result).to eql("programme")
      end
    end

    context "when the level is a third-party project" do
      it "returns a string for project" do
        result = described_class.new(level: :third_party_project).parent_level
        expect(result).to eql("project")
      end
    end
  end

  describe "#child_level" do
    context "when the level is a fund" do
      it "returns a string for programme" do
        result = described_class.new(level: :fund).child_level
        expect(result).to eql("programme")
      end
    end

    context "when the level is a programme" do
      it "returns a string for project" do
        result = described_class.new(level: :programme).child_level
        expect(result).to eql("project")
      end
    end

    context "when the level is a project" do
      it "returns a string for a third-party project" do
        result = described_class.new(level: :project).child_level
        expect(result).to eql("third_party_project")
      end
    end

    context "when the level is a third-party project" do
      it "returns nil" do
        expect { described_class.new(level: :third_party_project).child_level }
          .to raise_error("no level below third_party_project")
      end
    end
  end

  describe "#iati_identifier" do
    it "returns the previous_identifier if it exists" do
      activity = create(:project_activity, previous_identifier: "previous-id", transparency_identifier: "transparency-id")
      expect(activity.iati_identifier).to eq("previous-id")
    end

    it "returns the transparency_identifier if previous_identifier is not set" do
      activity = create(:project_activity, previous_identifier: nil, transparency_identifier: "transparency-id")
      expect(activity.iati_identifier).to eq("transparency-id")
    end
  end

  describe "#actual_total_for_report_financial_quarter" do
    let(:project) { create(:project_activity) }

    let(:q_1) { FinancialQuarter.for_date(Date.parse("01-May-2020")) }
    let(:q_2) { FinancialQuarter.for_date(Date.parse("01-Aug-2020")) }

    let(:q1_report) do
      create(
        :report,
        state: "approved",
        fund: project.associated_fund,
        organisation: project.organisation,
        **q_1
      )
    end

    let(:q2_report) do
      create(
        :report,
        fund: project.associated_fund,
        organisation: project.organisation,
        **q_2
      )
    end

    it "returns the total of all the activity's actuals scoped to a report" do
      create(
        :actual,
        parent_activity: project,
        value: 100.20,
        report: q2_report,
        **q_2
      )
      create(
        :actual,
        parent_activity: project,
        value: 50.00,
        report: q2_report,
        **q_2
      )
      create(
        :actual,
        parent_activity: project,
        value: 210,
        report: q1_report,
        **q_1
      )

      expect(project.actual_total_for_report_financial_quarter(report: q2_report)).to eq(150.20)
    end

    it "does NOT include Adjustments of type 'Actual' for a different financial quarter in the calculation" do
      create(
        :actual,
        parent_activity: project,
        value: 130.20,
        report: q2_report,
        **q_2
      )
      create(
        :adjustment,
        :actual,
        parent_activity: project,
        value: -30,
        report: q2_report,
        **q_1
      )

      expect(project.actual_total_for_report_financial_quarter(report: q2_report))
        .to eq(130.20)
    end

    it "does NOT include Adjustments reported later for same financial quarter" do
      create(
        :actual,
        parent_activity: project,
        value: 100.20,
        report: q1_report,
        **q_1
      )
      create(
        :actual,
        parent_activity: project,
        value: 50.00,
        report: q1_report,
        **q_1
      )
      create(
        :adjustment,
        :actual,
        parent_activity: project,
        value: -50,
        report: q2_report,
        **q_1
      )

      expect(project.actual_total_for_report_financial_quarter(report: q1_report))
        .to eq(150.20)
    end

    it "does not include the totals for any actuals outside the report's date range" do
      create(
        :actual,
        parent_activity: project,
        value: 100.20, report: q2_report,
        **q_1.pred
      )
      create(
        :actual,
        parent_activity: project,
        value: 210,
        report: q2_report,
        **q_1
      )

      expect(project.actual_total_for_report_financial_quarter(report: q2_report))
        .to eq(0)
    end
  end

  describe "#forecasted_total_for_report_financial_quarter" do
    let(:project) { create(:project_activity) }

    it "returns the activity's forecast value for a report's financial quarter" do
      forecast = ForecastHistory.new(project, financial_quarter: 3, financial_year: 2020)
      reporting_cycle = ReportingCycle.new(project, 2, 2020)

      reporting_cycle.tick
      forecast.set_value(1000.0)

      reporting_cycle.tick
      report = Report.for_activity(project).find_by(financial_quarter: 3)

      expect(project.forecasted_total_for_report_financial_quarter(report: report)).to eq(1000.00)
    end

    it "does not include totals for any forecasts outside the report's date range" do
      q3_forecast = ForecastHistory.new(project, financial_quarter: 3, financial_year: 2020)
      q4_forecast = ForecastHistory.new(project, financial_quarter: 4, financial_year: 2020)
      reporting_cycle = ReportingCycle.new(project, 2, 2020)

      reporting_cycle.tick
      q3_forecast.set_value(2000.0)
      q4_forecast.set_value(1000.0)

      reporting_cycle.tick
      report = Report.for_activity(project).find_by(financial_quarter: 3)

      expect(project.forecasted_total_for_report_financial_quarter(report: report)).to eq(2000.00)
    end

    it "only counts the latest revision value for a forecast" do
      forecast = ForecastHistory.new(project, financial_quarter: 3, financial_year: 2020)
      reporting_cycle = ReportingCycle.new(project, 1, 2020)

      reporting_cycle.tick
      forecast.set_value(3000.0)

      reporting_cycle.tick
      forecast.set_value(4000.0)

      reporting_cycle.tick
      report = Report.for_activity(project).find_by(financial_quarter: 3)

      expect(project.forecasted_total_for_report_financial_quarter(report: report)).to eq(4000.00)
    end
  end

  describe "#variance_for_report_financial_quarter" do
    before do
      start_of_third_quarter = Date.parse("2020-10-01")
      travel_to start_of_third_quarter
    end

    after { travel_back }

    let(:project) { create(:project_activity) }
    let(:reporting_cycle) { ReportingCycle.new(project, 2, 2020) }
    let(:forecast) { ForecastHistory.new(project, financial_quarter: 3, financial_year: 2020) }

    it "returns the variance between #actual_total_for_report_financial_quarter and #forecasted_total_for_report_financial_quarter" do
      reporting_cycle.tick
      forecast.set_value(1500)
      reporting_cycle.tick

      report = Report.for_activity(project).find_by(financial_quarter: 3)
      create(:actual, parent_activity: project, value: 100, report: report, date: Date.today)
      create(:actual, parent_activity: project, value: 200, report: report, date: Date.today)

      expect(project.variance_for_report_financial_quarter(report: report)).to eq(-1200)
    end
  end

  describe "#comments_for_report" do
    it "returns the comments associated to this activity and a particular report" do
      project = create(:project_activity, :with_report)
      report = Report.for_activity(project).first
      comment = create(:comment, commentable: project, report_id: report.id, body: "Here's my comment")
      expect(project.comments_for_report(report_id: report.id)).to include(comment)
      expect(project.comments_for_report(report_id: report.id).first.body).to eq "Here's my comment"
    end

    it "does not return any other comments associated to this activity but in another report" do
      project = create(:project_activity, :with_report)
      report = Report.for_activity(project).first
      comment = create(:comment, commentable: project, report_id: create(:report).id)
      expect(project.comments_for_report(report_id: report.id)).not_to include(comment)
      expect(project.comments_for_report(report_id: report.id)).to eq []
    end

    it "returns an empty array when there are no comments" do
      project = create(:project_activity, :with_report)
      report = Report.for_activity(project).first
      expect(project.comments_for_report(report_id: report.id)).to eq []

      comment = create(:comment, commentable: project, report_id: create(:report).id)
      expect(project.comments_for_report(report_id: report.id)).to_not include(comment)
    end
  end

  describe "#is_gcrf_funded?" do
    it "returns true if activity is associated with the GCRF fund" do
      programme = build(:programme_activity, :gcrf_funded)

      expect(programme.is_gcrf_funded?).to be_truthy
    end

    it "returns false if activity is not associated with the GCRF fund" do
      programme = build(:programme_activity, :newton_funded)

      expect(programme.is_gcrf_funded?).to be_falsey
    end

    it "returns false if activity is a fund" do
      fund = build(:fund_activity)

      expect(fund.is_gcrf_funded?).to be_falsey
    end
  end

  describe "#is_newton_funded?" do
    it "returns true if activity is associated with the Newton fund" do
      programme = build(:programme_activity, :newton_funded)

      expect(programme.is_newton_funded?).to be_truthy
    end

    it "returns false if activity is not associated with the Newton fund" do
      programme = build(:programme_activity, :gcrf_funded)

      expect(programme.is_newton_funded?).to be_falsey
    end

    it "returns false if activity is a fund" do
      fund = build(:fund_activity, :newton)

      expect(fund.is_newton_funded?).to be_falsey
    end
  end

  describe "#is_ispf_funded?" do
    it "returns true if activity is associated with the ISPF" do
      programme = build(:programme_activity, :ispf_funded)

      expect(programme.is_ispf_funded?).to be_truthy
    end

    it "returns false if activity is not associated with the ISPF" do
      programme = build(:programme_activity, :gcrf_funded)

      expect(programme.is_ispf_funded?).to be_falsey
    end

    it "returns false if activity is a fund" do
      fund = build(:fund_activity, :ispf)

      expect(fund.is_ispf_funded?).to be_falsey
    end
  end

  describe "#iati_status" do
    context "when the activity does not have a programme status set" do
      it "returns nil" do
        activity = Activity.new
        expect(activity.iati_status).to be_nil
      end
    end

    context "when the programme status exists" do
      it "returns the corresponding IATI status code" do
        activity = Activity.new(programme_status: "spend_in_progress")
        expect(activity.iati_status).to eql "2"
      end
    end

    context "when the programme status is an invalid text string" do
      it "raises an error" do
        expect { Activity.new(programme_status: "kitten") }.to raise_error("'kitten' is not a valid programme_status")
      end
    end
  end

  describe ".hierarchically_grouped_projects" do
    before do
      first_project = create(:project_activity, roda_identifier: "zzxx")
      create(:third_party_project_activity, roda_identifier: "ww", parent: first_project)

      _second_project = create(:project_activity, roda_identifier: "mmnn")

      third_project = create(:project_activity, roda_identifier: "aabb")
      (1..3).each do |i|
        create(:third_party_project_activity, roda_identifier: "cc#{3 - i}", parent: third_project)
      end
    end

    it "returns projects followed by their third-party project children" do
      result = Activity.all.hierarchically_grouped_projects

      expect(result.map(&:roda_identifier)).to eq(["aabb", "cc0", "cc1", "cc2", "mmnn", "zzxx", "ww"])
    end
  end

  describe "#source_fund" do
    context "for a Newton fund activity" do
      let(:activity) { build(:project_activity, source_fund_code: Fund.by_short_name("NF").id) }

      it "returns a Newton fund" do
        expect(activity.source_fund).to be_a(Fund)
        expect(activity.source_fund.name).to eq("Newton Fund")
        expect(activity.source_fund.id).to eq(1)
      end
    end

    context "for a GCRF activity" do
      let(:activity) { build(:project_activity, source_fund_code: Fund.by_short_name("GCRF").id) }

      it "returns a GCRF fund" do
        expect(activity.source_fund).to be_a(Fund)
        expect(activity.source_fund.name).to eq("Global Challenges Research Fund")
        expect(activity.source_fund.short_name).to eq("GCRF")
        expect(activity.source_fund.id).to eq(2)
      end
    end
  end

  describe "#source_fund=" do
    it "sets the source fund code" do
      activity = build(:project_activity)
      activity.source_fund = Fund.new(Fund.by_short_name("GCRF").id)
      activity.save

      expect(activity.reload.source_fund_code).to eq(2)
    end
  end

  context "with descendants" do
    let!(:fund) { create(:fund_activity) }
    let!(:programme1) { create(:programme_activity, parent: fund) }
    let!(:programme2) { create(:programme_activity, parent: fund) }
    let!(:programme1_projects) { create_list(:project_activity, 2, parent: programme1) }
    let!(:programme2_projects) { create_list(:project_activity, 2, parent: programme2) }
    let!(:programme1_third_party_project) { create(:third_party_project_activity, parent: programme1_projects[0]) }
    let!(:programme2_third_party_project) { create(:third_party_project_activity, parent: programme2_projects[1]) }

    describe "#descendants" do
      it "returns all of the activities in a fund" do
        expect(fund.descendants).to match_array([
          programme1,
          programme2,
          programme1_projects,
          programme2_projects,
          programme1_third_party_project,
          programme2_third_party_project
        ].flatten)
      end

      it "returns all the activities in a programme" do
        expect(programme1.descendants).to match_array([
          programme1_projects,
          programme1_third_party_project
        ].flatten)

        expect(programme2.descendants).to match_array([
          programme2_projects,
          programme2_third_party_project
        ].flatten)
      end

      it "returns all the activities in a project" do
        expect(programme1_projects[0].descendants).to match_array([
          programme1_third_party_project
        ].flatten)
        expect(programme1_projects[1].descendants).to eq([])

        expect(programme2_projects[0].descendants).to eq([])
        expect(programme2_projects[1].descendants).to match_array([
          programme2_third_party_project
        ].flatten)
      end
    end

    describe "#total_spend" do
      before do
        create(:actual, value: 100, parent_activity: fund)
        create(:actual, value: 100, parent_activity: fund, financial_year: 2020, financial_quarter: 1)

        create(:actual, value: 100, parent_activity: programme1)
        create(:actual, value: 100, parent_activity: programme1, financial_year: 2020, financial_quarter: 1)

        create(:actual, value: 100, parent_activity: programme2)
        create(:actual, value: 100, parent_activity: programme2, financial_year: 2020, financial_quarter: 1)

        create(:actual, value: 50, parent_activity: programme1_projects[0])
        create(:actual, value: 50, parent_activity: programme1_projects[0], financial_year: 2020, financial_quarter: 1)

        create(:actual, value: 50, parent_activity: programme1_projects[1])
        create(:actual, value: 50, parent_activity: programme1_projects[1], financial_year: 2020, financial_quarter: 1)

        create(:actual, value: 100, parent_activity: programme2_projects[0])
        create(:actual, value: 100, parent_activity: programme2_projects[0], financial_year: 2020, financial_quarter: 1)

        create(:actual, value: 100, parent_activity: programme2_projects[1])
        create(:actual, value: 100, parent_activity: programme2_projects[1], financial_year: 2020, financial_quarter: 1)

        create(:actual, value: 100, parent_activity: programme1_third_party_project)
        create(:actual, value: 100, parent_activity: programme1_third_party_project, financial_year: 2020, financial_quarter: 1)

        create(:actual, value: 100, parent_activity: programme2_third_party_project)
        create(:actual, value: 100, parent_activity: programme2_third_party_project, financial_year: 2020, financial_quarter: 1)
      end

      context "when quarter is not specified" do
        it "returns the total spend for a fund" do
          expect(fund.total_spend).to eq(1600)
        end

        it "returns the total spend for a programme" do
          expect(programme1.total_spend).to eq(600)
          expect(programme2.total_spend).to eq(800)
        end

        it "returns the total spend for a project" do
          expect(programme1_projects[0].total_spend).to eq(300)
          expect(programme1_projects[1].total_spend).to eq(100)

          expect(programme2_projects[0].total_spend).to eq(200)
          expect(programme2_projects[1].total_spend).to eq(400)
        end

        it "accounts for refunds and adjustments" do
          create(:refund, value: 25, parent_activity: programme2_projects[1])

          expect(programme2_projects[1].total_spend).to eq(375)
          expect(programme2.total_spend).to eq(775)
          expect(fund.total_spend).to eq(1575)

          create(:adjustment, value: 5, parent_activity: programme2_projects[1])

          expect(programme2_projects[1].total_spend).to eq(380)
          expect(programme2.total_spend).to eq(780)
          expect(fund.total_spend).to eq(1580)
        end
      end

      context "when quarter is specified" do
        let(:quarter) { FinancialQuarter.new(2020, 1) }

        it "returns the total spend for a fund" do
          expect(fund.total_spend(quarter)).to eq(800)
        end

        it "returns the total spend for a programme" do
          expect(programme1.total_spend(quarter)).to eq(300)
          expect(programme2.total_spend(quarter)).to eq(400)
        end

        it "returns the total spend for a project" do
          expect(programme1_projects[0].total_spend(quarter)).to eq(150)
          expect(programme1_projects[1].total_spend(quarter)).to eq(50)

          expect(programme2_projects[0].total_spend(quarter)).to eq(100)
          expect(programme2_projects[1].total_spend(quarter)).to eq(200)
        end
      end
    end

    describe "#total_budget" do
      let(:activity) { programme1 }

      let!(:external_budget) { create(:budget, :other_official_development_assistance, value: rand(100..200), parent_activity: activity) }

      context "when there is one direct budget for an activity" do
        let!(:budget) do
          create(:budget, :direct, value: rand(100..200), parent_activity: activity)
        end

        it "only includes the direct budget in the calculations" do
          expect(activity.total_budget).to eq(budget.value)
        end
      end

      context "when there are multiple direct budgets for an activity" do
        let!(:direct_budgets) do
          create_list(:budget, 5, :direct, value: rand(100..200), parent_activity: activity)
        end

        it "sums all of the direct budget" do
          expect(activity.total_budget).to eq(direct_budgets.sum(&:value))
        end
      end
    end

    describe "#total_forecasted" do
      let(:quarter) { FinancialQuarter.new(Date.today.year + 2, 3) }

      def create_report(organisation, fund)
        create(:report, :active, organisation: organisation, fund: fund, **quarter.pred)
      end

      before do
        Organisation.all.each do |organisation|
          Activity.fund.each { |fund| create_report(organisation, fund) }
        end

        forecasts = [
          [fund, quarter, 10],

          [programme1, quarter, 20],
          [programme1, quarter.succ, 40],

          [programme1_projects[0], quarter, 80],
          [programme1_projects[1], quarter, 160],

          [programme1_third_party_project, quarter, 320],
          [programme1_third_party_project, quarter.succ, 640],

          [programme2, quarter, 1280],
          [programme2, quarter.succ, 2560],

          [programme2_projects[0], quarter, 5120],
          [programme2_projects[1], quarter, 10240]
        ]

        forecasts.each do |activity, quarter, value|
          ForecastHistory.new(activity, **quarter).set_value(value)
        end
      end

      it "returns the total forecasted spend for a fund" do
        expect(fund.total_forecasted).to eq([10, 20, 40, 80, 160, 320, 640, 1280, 2560, 5120, 10240].sum)
      end

      it "returns total forecasted spend for a programme" do
        expect(programme1.total_forecasted).to eq([20, 40, 80, 160, 320, 640].sum)
        expect(programme2.total_forecasted).to eq([1280, 2560, 5120, 10240].sum)
      end

      it "returns total forecasted spend for a project" do
        expect(programme1_projects[0].total_forecasted).to eq([80, 320, 640].sum)
        expect(programme1_projects[1].total_forecasted).to eq(160)
        expect(programme2_projects[0].total_forecasted).to eq(5120)
        expect(programme2_projects[1].total_forecasted).to eq(10240)
      end

      context "when a report exists for forecasted periods ('quarter')" do
        before do
          create(
            :report,
            :approved,
            organisation: programme1.organisation,
            fund: programme1.associated_fund,
            **quarter
          )
        end

        it "includes only forecasts for later periods ('quarter.succ')" do
          expect(programme1.total_forecasted).to eq([40, 640].sum)
        end
      end

      context "when a level A/B forecast is revised" do
        let(:programme) { programme2 }

        before do
          ForecastHistory.new(programme, **quarter).set_value(20480)
        end

        it "only includes the latest version's value in the total" do
          expect(programme.total_forecasted).to eq([20480, 2560, 5120, 10240].sum)
        end
      end

      context "when there are versions of level C/D forecasts in older reports" do
        let(:project) { programme1_projects[0] }
        let(:old_report) { create(:report, :approved, organisation: project.organisation, fund: project.associated_fund, **quarter.pred.pred) }

        before do
          ForecastHistory.new(project, report: old_report, **quarter).set_value(70)
        end

        it "excludes the old version from the total" do
          expect(project.total_forecasted).to eq([80, 320, 640].sum)
        end
      end
    end

    describe "#own_and_descendants_associates" do
      let!(:fund_actual) { create(:actual, value: 100, parent_activity: fund) }
      let!(:programme1_actual) { create(:actual, value: 100, parent_activity: programme1) }
      let!(:programme2_actual) { create(:actual, value: 100, parent_activity: programme2) }
      let!(:programme1_projects1_actual) { create(:actual, value: 50, parent_activity: programme1_projects[0]) }
      let!(:programme1_projects2_actual) { create(:actual, value: 50, parent_activity: programme1_projects[1]) }
      let!(:programme2_projects1_actual) { create(:actual, value: 100, parent_activity: programme2_projects[0]) }
      let!(:programme2_projects2_actual) { create(:actual, value: 100, parent_activity: programme2_projects[1]) }
      let!(:programme1_tpp_actual) { create(:actual, value: 100, parent_activity: programme1_third_party_project) }
      let!(:programme2_tpp_actual) { create(:actual, value: 100, parent_activity: programme2_third_party_project) }

      it "returns all the actuals belonging to the activity and to the descendant activities" do
        expect(fund.own_and_descendants_associates(Actual).pluck(:id)).to match_array([
          fund_actual.id,
          programme1_actual.id,
          programme2_actual.id,
          programme1_projects1_actual.id,
          programme1_projects2_actual.id,
          programme2_projects1_actual.id,
          programme2_projects2_actual.id,
          programme1_tpp_actual.id,
          programme2_tpp_actual.id
        ])
      end
    end

    describe "#net_spend_by_financial_quarter" do
      let(:organisation) { create(:partner_organisation) }
      let(:programme) { create(:programme_activity, extending_organisation: organisation) }
      let(:projects) { create_list(:project_activity, 2, parent: programme) }
      let(:third_party_project) { create(:third_party_project_activity, parent: projects[0]) }

      before do
        create(:actual, value: 500, parent_activity: projects[0], financial_year: 2020, financial_quarter: 1)
        create(:actual, value: 500, parent_activity: projects[1], financial_year: 2020, financial_quarter: 1)
        create(:actual, value: 200, parent_activity: third_party_project, financial_year: 2020, financial_quarter: 1)

        create(:actual, value: 1000, parent_activity: programme, financial_year: 2018, financial_quarter: 2)

        create(:actual, value: 1000, parent_activity: programme, financial_year: 2018, financial_quarter: 1)
        create(:actual, value: 500, parent_activity: projects[0], financial_year: 2018, financial_quarter: 1)
        create(:actual, value: 500, parent_activity: projects[1], financial_year: 2018, financial_quarter: 1)
        create(:actual, value: 200, parent_activity: third_party_project, financial_year: 2018, financial_quarter: 1)
      end

      context "when the activity is a programme" do
        it "sums up the transactions of the activity and child activities by financial quarter" do
          net_spend_by_financial_quarter = programme.net_spend_by_financial_quarter
          expect(net_spend_by_financial_quarter.map(&:value)).to eq([1200, 1000, 2200])
          expect(net_spend_by_financial_quarter.map(&:date)).to eq(
            [
              FinancialQuarter.new(2020, 1).end_date,
              FinancialQuarter.new(2018, 2).end_date,
              FinancialQuarter.new(2018, 1).end_date
            ]
          )
        end
      end

      context "when the activity is a project or third-party project" do
        it "sums up the transactions of the activity" do
          projects.each { |project| expect(project.net_spend_by_financial_quarter.map(&:value)).to eq([500, 500]) }

          expect(third_party_project.net_spend_by_financial_quarter.map(&:value)).to eq([200, 200])

          [*projects, third_party_project].each do |activity|
            expect(activity.net_spend_by_financial_quarter.map(&:date)).to eq(
              [FinancialQuarter.new(2020, 1).end_date, FinancialQuarter.new(2018, 1).end_date]
            )
          end
        end
      end

      it "accounts for refunds and adjustments" do
        create(:refund, value: 500, parent_activity: programme, financial_year: 2018, financial_quarter: 2)

        expect(programme.net_spend_by_financial_quarter.second.value).to eq(500)

        create(:adjustment, value: 50, parent_activity: programme, financial_year: 2018, financial_quarter: 2)

        expect(programme.net_spend_by_financial_quarter.second.value).to eq(550)
      end
    end
  end

  describe "#benefitting_region" do
    let(:activity) { build(:programme_activity, benefitting_countries: benefitting_countries) }

    subject { activity.benefitting_region }

    context "when there are countries present" do
      let(:benefitting_countries) { ["ZA", "ZW"] }
      let(:region) { BenefittingRegion.new }

      it "returns a region" do
        expect(BenefittingCountry).to receive(:region_from_country_codes).with(benefitting_countries).and_return(region)
        expect(subject).to eq(region)
      end
    end

    context "when there are not benefitting countries present" do
      let(:benefitting_countries) { [] }

      it "returns nil" do
        expect(BenefittingCountry).to_not receive(:region_from_country_codes).with(benefitting_countries)
        expect(subject).to eq(nil)
      end
    end

    context "when there is an unexpected country" do
      let(:benefitting_countries) { ["UK", "DZ", "LY"] }
      let(:region) { BenefittingRegion.find_by_code("189") }

      it "handles the unexpected country and returns the region that can be derived" do
        expect(subject).to eql(region)
      end
    end

    context "when there is a graduated country" do
      let(:benefitting_countries) { ["SC", "KM", "BI"] }
      let(:region) { BenefittingRegion.find_by_code("1027") }

      it "handles graduated countries including them in the region calculation" do
        expect(subject).to eql(region)
      end
    end
  end

  %w[requires_objectives? requires_gdi?].each do |method|
    describe "##{method}" do
      context "when activity is a fund" do
        let(:activity) { build(:fund_activity) }

        it "returns false" do
          expect(activity.send(method.to_sym)).to be(false)
        end
      end

      context "when activity is a programme" do
        context "when is_oda is nil" do
          let(:activity) { build(:programme_activity, :newton_funded) }

          it "returns true" do
            expect(activity.send(method.to_sym)).to be(true)
          end
        end

        context "when is_oda is true" do
          let(:activity) { build(:programme_activity, :ispf_funded) }

          it "returns true" do
            expect(activity.send(method.to_sym)).to be(true)
          end
        end

        context "when is_oda is false" do
          let(:activity) { build(:programme_activity, :ispf_funded, is_oda: false) }

          it "returns false" do
            expect(activity.send(method.to_sym)).to be(false)
          end
        end
      end

      ["project", "third-party project"].each do |level|
        context "when activity is a #{level}" do
          let(:factory_name) { factory_name_by_activity_level(level) }

          context "when is_oda is nil" do
            let(:activity) { build(factory_name, :newton_funded) }

            it "returns true" do
              expect(activity.send(method.to_sym)).to be(true)
            end
          end

          context "when is_oda is true" do
            let(:activity) { build(factory_name, :ispf_funded) }

            it "returns true" do
              expect(activity.send(method.to_sym)).to be(true)
            end
          end

          context "when is_oda is false" do
            let(:activity) { build(factory_name, :ispf_funded, is_oda: false) }

            it "returns false" do
              expect(activity.send(method.to_sym)).to be(false)
            end
          end
        end
      end
    end
  end

  %w[
    requires_benefitting_countries?
    requires_aid_type?
    requires_oda_eligibility?
  ].each do |method|
    describe "##{method}" do
      context "when activity is a fund" do
        let(:activity) { build(:fund_activity) }

        it "returns true" do
          expect(activity.send(method.to_sym)).to be(true)
        end
      end

      context "when activity is a programme" do
        context "when is_oda is nil" do
          let(:activity) { build(:programme_activity, :newton_funded) }

          it "returns true" do
            expect(activity.send(method.to_sym)).to be(true)
          end
        end

        context "when is_oda is true" do
          let(:activity) { build(:programme_activity, :ispf_funded) }

          it "returns true" do
            expect(activity.send(method.to_sym)).to be(true)
          end
        end

        context "when is_oda is false" do
          let(:activity) { build(:programme_activity, :ispf_funded, is_oda: false) }

          it "returns false" do
            expect(activity.send(method.to_sym)).to be(false)
          end
        end
      end

      ["project", "third-party project"].each do |level|
        context "when activity is a #{level}" do
          let(:factory_name) { factory_name_by_activity_level(level) }

          context "when is_oda is nil" do
            let(:activity) { build(factory_name, :newton_funded) }

            it "returns true" do
              expect(activity.send(method.to_sym)).to be(true)
            end
          end

          context "when is_oda is true" do
            let(:activity) { build(factory_name, :ispf_funded) }

            it "returns true" do
              expect(activity.send(method.to_sym)).to be(true)
            end
          end

          context "when is_oda is false" do
            let(:activity) { build(factory_name, :ispf_funded, is_oda: false) }

            it "returns false" do
              expect(activity.send(method.to_sym)).to be(false)
            end
          end
        end
      end
    end
  end

  %w[requires_oda_eligibility_lead? requires_channel_of_delivery_code? requires_policy_markers?].each do |method|
    describe "##{method}" do
      context "when activity is a fund" do
        let(:activity) { build(:fund_activity) }

        it "returns false" do
          expect(activity.send(method.to_sym)).to be(false)
        end
      end

      context "when activity is a programme" do
        let(:activity) { build(:programme_activity) }

        it "returns false" do
          expect(activity.send(method.to_sym)).to be(false)
        end
      end

      ["project", "third-party project"].each do |level|
        context "when activity is a #{level}" do
          let(:factory_name) { factory_name_by_activity_level(level) }

          context "when is_oda is nil" do
            let(:activity) { build(factory_name, :newton_funded) }

            it "returns true" do
              expect(activity.send(method.to_sym)).to be(true)
            end
          end

          context "when is_oda is true" do
            let(:activity) { build(factory_name, :ispf_funded) }

            it "returns true" do
              expect(activity.send(method.to_sym)).to be(true)
            end
          end

          context "when is_oda is false" do
            let(:activity) { build(factory_name, :ispf_funded, is_oda: false) }

            it "returns false" do
              expect(activity.send(method.to_sym)).to be(false)
            end
          end
        end
      end
    end
  end

  %w[requires_covid19_related? requires_fstc_applies?].each do |method|
    describe "##{method}" do
      context "when activity is a fund" do
        let(:activity) { build(:fund_activity) }

        it "returns true" do
          expect(activity.send(method.to_sym)).to be(true)
        end
      end
    end

    context "when activity is a programme" do
      context "when Newton-funded" do
        let(:activity) { build(:programme_activity, :newton_funded) }

        it "returns true" do
          expect(activity.send(method.to_sym)).to be(true)
        end
      end

      context "when GCRF-funded" do
        let(:activity) { build(:programme_activity, :gcrf_funded) }

        it "returns true" do
          expect(activity.send(method.to_sym)).to be(true)
        end
      end

      context "when ISPF-funded" do
        let(:activity) { build(:programme_activity, :ispf_funded) }

        it "returns false" do
          expect(activity.send(method.to_sym)).to be(false)
        end
      end
    end

    ["project", "third-party project"].each do |level|
      context "when activity is a #{level}" do
        let(:factory_name) { factory_name_by_activity_level(level) }

        context "when is_oda is nil" do
          let(:activity) { build(factory_name, :newton_funded) }

          it "returns true" do
            expect(activity.send(method.to_sym)).to be(true)
          end
        end

        context "when is_oda is true" do
          let(:activity) { build(factory_name, :ispf_funded) }

          it "returns true" do
            expect(activity.send(method.to_sym)).to be(true)
          end
        end

        context "when is_oda is false" do
          let(:activity) { build(factory_name, :ispf_funded, is_oda: false) }

          it "returns false" do
            expect(activity.send(method.to_sym)).to be(false)
          end
        end
      end
    end
  end

  describe "#requires_collaboration_type?" do
    context "when activity is a fund" do
      let(:activity) { build(:fund_activity) }

      it "returns false" do
        expect(activity.requires_collaboration_type?).to be(false)
      end
    end

    context "when activity is a programme" do
      context "when Newton-funded" do
        let(:activity) { build(:programme_activity, :newton_funded) }

        it "returns true" do
          expect(activity.requires_collaboration_type?).to be(true)
        end
      end

      context "when GCRF-funded" do
        let(:activity) { build(:programme_activity, :gcrf_funded) }

        it "returns true" do
          expect(activity.requires_collaboration_type?).to be(true)
        end
      end

      context "when ISPF-funded" do
        let(:activity) { build(:programme_activity, :ispf_funded) }

        it "returns false" do
          expect(activity.requires_collaboration_type?).to be(false)
        end
      end
    end

    describe "#requires_is_oda?" do
      context "when the activity is an ISPF-funded programme with no `is_oda` value set" do
        let(:programme) { build(:programme_activity, :ispf_funded, is_oda: nil) }

        it "returns true" do
          expect(programme.requires_is_oda?).to be(true)
        end
      end

      context "when the activity is not ISPF-funded" do
        let(:programme) { build(:programme_activity, :newton_funded) }

        it "returns false" do
          expect(programme.requires_is_oda?).to be(false)
        end
      end

      context "when the activity is not a programme" do
        let(:project) { build(:project_activity, :ispf_funded) }

        it "returns false" do
          expect(project.requires_is_oda?).to be(false)
        end
      end

      context "when the activity already has a non-nil `is_oda` value" do
        let(:programme) { build(:programme_activity, :ispf_funded, is_oda: true) }

        it "returns false" do
          expect(programme.requires_is_oda?).to be(false)
        end
      end
    end

    ["project", "third-party project"].each do |level|
      context "when activity is a #{level}" do
        let(:factory_name) { factory_name_by_activity_level(level) }

        context "when is_oda is nil" do
          let(:activity) { build(factory_name, :newton_funded) }

          it "returns true" do
            expect(activity.requires_collaboration_type?).to be(true)
          end
        end

        context "when is_oda is true" do
          let(:activity) { build(factory_name, :ispf_funded) }

          it "returns true" do
            expect(activity.requires_collaboration_type?).to be(true)
          end
        end

        context "when is_oda is false" do
          let(:activity) { build(factory_name, :ispf_funded, is_oda: false) }

          it "returns false" do
            expect(activity.requires_collaboration_type?).to be(false)
          end
        end
      end
    end
  end

  describe "#is_non_oda?" do
    context "when activity is a fund" do
      let(:activity) { build(:fund_activity) }

      it "returns false" do
        expect(activity.is_non_oda?).to be(false)
      end
    end

    context "when activity is a programme" do
      context "when is_oda is nil" do
        let(:activity) { build(:programme_activity, :newton_funded) }

        it "returns false" do
          expect(activity.is_non_oda?).to be(false)
        end
      end

      context "when is_oda is true" do
        let(:activity) { build(:programme_activity, :ispf_funded) }

        it "returns false" do
          expect(activity.is_non_oda?).to be(false)
        end
      end

      context "when is_oda is false" do
        let(:activity) { build(:programme_activity, :ispf_funded, is_oda: false) }

        it "returns true" do
          expect(activity.is_non_oda?).to be(true)
        end
      end
    end

    ["project", "third-party project"].each do |level|
      context "when activity is a #{level}" do
        let(:factory_name) { factory_name_by_activity_level(level) }

        context "when is_oda is nil" do
          let(:activity) { build(factory_name, :newton_funded) }

          it "returns false" do
            expect(activity.is_non_oda?).to be(false)
          end
        end

        context "when is_oda is true" do
          let(:activity) { build(factory_name, :ispf_funded) }

          it "returns false" do
            expect(activity.is_non_oda?).to be(false)
          end
        end

        context "when is_oda is false" do
          let(:activity) { build(factory_name, :ispf_funded, is_oda: false) }

          it "returns true" do
            expect(activity.is_non_oda?).to be(true)
          end
        end
      end
    end
  end

  describe "#ensure_linked_activity_reciprocity" do
    let(:partner_organisation) { create(:partner_organisation) }
    let(:oda_programme) { create(:programme_activity, :ispf_funded, extending_organisation: partner_organisation, is_oda: true) }
    let(:non_oda_programme) { create(:programme_activity, :ispf_funded, extending_organisation: partner_organisation, is_oda: false, linked_activity: oda_programme) }

    let(:oda_project) {
      create(:project_activity,
        :ispf_funded,
        is_oda: true,
        parent: oda_programme,
        extending_organisation: partner_organisation)
    }

    let(:non_oda_project) {
      create(:project_activity,
        :ispf_funded,
        is_oda: false,
        parent: non_oda_programme,
        extending_organisation: partner_organisation)
    }

    context "when adding a linked activity" do
      it "links the newly linked activity back to self" do
        non_oda_project.linked_activity = oda_project
        non_oda_project.save

        oda_project.reload
        expect(oda_project.linked_activity).to eq(non_oda_project)
      end
    end

    context "when removing a linked activity" do
      it "unlinks the old activity from self" do
        non_oda_project.linked_activity = nil
        non_oda_project.save

        oda_project.reload
        expect(oda_project.linked_activity).to be_nil
      end
    end

    context "when replacing a linked activity with another" do
      before do
        allow(non_oda_programme).to receive(:linked_child_activities).and_return([])
        allow(oda_programme).to receive(:linked_child_activities).and_return([])
      end

      it "links the newly linked activities reciprocally" do
        # Given a pair of linked activities and an unlinked activity
        replacement_non_oda_programme = create(:programme_activity, :ispf_funded,
          is_oda: false,
          extending_organisation: partner_organisation)

        # When I change the oda_activity's linked_activity to replacement_non_oda_programme
        oda_programme.linked_activity = replacement_non_oda_programme
        oda_programme.save!

        # Then oda_programme and replacement_non_oda_programme should be mutually linked
        expect(oda_programme.reload.linked_activity).to eq(replacement_non_oda_programme)
        expect(replacement_non_oda_programme.reload.linked_activity).to eq(oda_programme)
      end
    end
  end

  describe "#linkable_activities" do
    let(:partner_organisation) { create(:partner_organisation) }
    let(:oda_programme) { create(:programme_activity, :ispf_funded, extending_organisation: partner_organisation, is_oda: true) }
    let(:non_oda_programme) { create(:programme_activity, :ispf_funded, extending_organisation: partner_organisation, is_oda: false) }

    let!(:oda_project) {
      create(
        :project_activity,
        :ispf_funded,
        extending_organisation: partner_organisation,
        is_oda: true,
        parent: oda_programme
      )
    }

    let!(:non_oda_project) {
      create(
        :project_activity,
        :ispf_funded,
        extending_organisation: partner_organisation,
        is_oda: false,
        parent: non_oda_programme
      )
    }

    context "when the activity is a fund" do
      it "returns an empty array" do
        ispf = create(:fund_activity, :ispf)
        create(:fund_activity)

        expect(ispf.linkable_activities).to be_empty
      end
    end

    context "when the activity is an ODA ISPF programme" do
      it "returns unlinked non-ODA ISPF programmes with the same PO as their extending organisation" do
        _other_po_non_oda_programme = create(:programme_activity, :ispf_funded, is_oda: false)
        _other_oda_programme = create(:programme_activity, :ispf_funded, is_oda: true)
        _prelinked_non_oda_programme = create(
          :programme_activity, :ispf_funded,
          extending_organisation: partner_organisation,
          is_oda: false,
          linked_activity: build(:programme_activity, :ispf_funded, extending_organisation: partner_organisation)
        )

        expect(oda_programme.linkable_activities).to eq([non_oda_programme])
      end
    end

    context "when the activity is a non-ODA ISPF programme" do
      it "returns unlinked ODA ISPF programmes with the same PO as their extending organisation" do
        _other_po_oda_programme = create(:programme_activity, :ispf_funded, is_oda: true)
        _other_non_oda_programme = create(:programme_activity, :ispf_funded, is_oda: false)
        _prelinked_oda_programme = create(:programme_activity,
          :ispf_funded,
          extending_organisation: partner_organisation,
          is_oda: true,
          linked_activity: build(:programme_activity, :ispf_funded, extending_organisation: partner_organisation, is_oda: false))

        expect(non_oda_programme.linkable_activities).to eq([oda_programme])
      end
    end

    context "when the activity is already linked to another activity" do
      it "includes the already linked activity" do
        oda_programme.linked_activity = non_oda_programme
        oda_programme.save

        expect(oda_programme.reload.linkable_activities).to eq([non_oda_programme])
      end
    end

    context "when the activity is an ISPF project" do
      context "and its parent programme has no linked activity" do
        it "returns an empty array" do
          expect(oda_project.linkable_activities).to be_empty
        end
      end

      context "and its parent programme has a linked activity" do
        before do
          oda_programme.linked_activity = non_oda_programme
          oda_programme.save

          prelinked_oda_project = create(:project_activity,
            :ispf_funded,
            is_oda: true,
            parent: oda_programme,
            extending_organisation: partner_organisation)

          _prelinked_non_oda_project = create(:project_activity,
            :ispf_funded,
            is_oda: false,
            parent: non_oda_programme,
            extending_organisation: partner_organisation,
            linked_activity: prelinked_oda_project)
        end

        it "returns unlinked child projects of the parent's linked programme" do
          expect(oda_project.linkable_activities).to eq([non_oda_project])
        end

        context "when the project is already linked to another project" do
          it "includes the already linked project" do
            oda_project.linked_activity = non_oda_project
            oda_project.save

            expect(oda_project.linkable_activities).to eq([non_oda_project])
          end
        end
      end
    end

    context "when the activity is an ISPF third-party project" do
      let!(:oda_3rdp_project) {
        create(:third_party_project_activity,
          :ispf_funded,
          organisation: partner_organisation,
          is_oda: true,
          parent: oda_project)
      }

      let!(:non_oda_3rdp_project) {
        create(:third_party_project_activity,
          :ispf_funded,
          organisation: partner_organisation,
          is_oda: false,
          parent: non_oda_project)
      }

      context "and its parent project has no linked activity" do
        it "returns an empty array" do
          expect(oda_3rdp_project.linkable_activities).to be_empty
        end
      end

      context "and its parent project has a linked activity" do
        before do
          oda_programme.linked_activity = non_oda_programme
          oda_programme.save

          oda_project.linked_activity = non_oda_project
          oda_project.save

          prelinked_oda_3rdp_project = create(
            :third_party_project_activity,
            :ispf_funded,
            is_oda: true,
            parent: oda_project,
            extending_organisation: partner_organisation
          )

          prelinked_non_oda_3rdp_project = create(
            :third_party_project_activity,
            :ispf_funded,
            is_oda: false,
            parent: non_oda_project,
            extending_organisation: partner_organisation
          )

          prelinked_oda_3rdp_project.linked_activity = prelinked_non_oda_3rdp_project
          prelinked_oda_3rdp_project.save
        end

        it "returns unlinked child third-party projects of the parent's linked project" do
          expect(oda_3rdp_project.linkable_activities).to eq([non_oda_3rdp_project])
        end

        context "when the third-party project is already linked to another third-party project" do
          it "includes the already linked project" do
            oda_3rdp_project.linked_activity = non_oda_3rdp_project
            oda_3rdp_project.save

            expect(oda_3rdp_project.linkable_activities).to eq([non_oda_3rdp_project])
          end
        end
      end
    end
  end

  def factory_name_by_activity_level(level)
    (level.underscore.parameterize(separator: "_") + "_activity").to_sym
  end
end
