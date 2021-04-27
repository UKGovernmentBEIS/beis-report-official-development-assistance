require "rails_helper"

RSpec.describe Activity, type: :model do
  describe "#finance" do
    it "always returns Standard Grant, code '110'" do
      activity = Activity.new
      expect(activity.finance).to eq "110"
    end
  end

  describe "#tied_status" do
    it "always returns Untied, code '5'" do
      activity = Activity.new
      expect(activity.tied_status).to eq "5"
    end
  end

  describe "#capital_spend" do
    it "always returns 0" do
      activity = Activity.new
      expect(activity.capital_spend).to eq 0
    end
  end

  describe "#flow" do
    it "always returns the default ODA flow type, code '10'" do
      activity = Activity.new
      expect(activity.flow).to eq "10"
    end
  end

  describe ".new_child" do
    let(:parent_activity) { create(:fund_activity, :newton) }
    let(:delivery_partner_organisation) { create(:delivery_partner_organisation) }

    before do
      allow_any_instance_of(ActivityDefaults).to receive(:call).and_return(
        title: "a returned value",
        form_state: "form_state"
      )
    end

    it "initialises a new activity with the attribute hash from ActivityDefaults" do
      activity = Activity.new_child(
        parent_activity: parent_activity,
        delivery_partner_organisation: delivery_partner_organisation
      )

      expect(activity).to be_an_instance_of(Activity)
      expect(activity.title).to eq "a returned value"
      expect(activity.form_state).to eq "form_state"
    end

    it "accepts a block that can override any default values" do
      parent_activity = create(:fund_activity, :newton)
      delivery_partner_organisation = create(:delivery_partner_organisation)

      activity = Activity.new_child(
        parent_activity: parent_activity,
        delivery_partner_organisation: delivery_partner_organisation
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

    describe ".projects_and_third_party_projects_for_report" do
      it "only returns projects and third party projects that are for the reports organisation and fund" do
        organisation = create(:delivery_partner_organisation)
        fund = create(:fund_activity)
        programme = create(:programme_activity, parent: fund, organisation: organisation)
        project = create(:project_activity, parent: programme, organisation: organisation)
        third_party_project = create(:third_party_project_activity, parent: project, organisation: organisation)
        report = create(:report, organisation: third_party_project.organisation, fund: fund)

        another_fund = create(:fund_activity)
        another_programme = create(:programme_activity, parent: another_fund, organisation: organisation)
        another_project = create(:project_activity, parent: another_programme, organisation: organisation)
        another_third_party_project = create(:third_party_project_activity, parent: another_project, organisation: organisation)

        result = Activity.projects_and_third_party_projects_for_report(report)

        expect(result).to include third_party_project
        expect(result).to include project

        expect(result).not_to include fund
        expect(result).not_to include programme
        expect(result).not_to include another_fund
        expect(result).not_to include another_programme
        expect(result).not_to include another_project
        expect(result).not_to include another_third_party_project
      end
    end
  end

  describe "sanitisation" do
    it { should strip_attribute(:delivery_partner_identifier) }
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

    context "when activity is a fund" do
      subject { build(:fund_activity, organisation: organisation) }

      context "when the organisation is a delivery partner" do
        let(:organisation) { build(:delivery_partner_organisation) }

        it { should be_invalid }
      end

      context "when the organisation is the service owner" do
        let(:organisation) { build(:beis_organisation) }

        it { should be_valid }
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

    context "when delivery_partner_identifier is blank" do
      subject(:activity) { build(:project_activity, delivery_partner_identifier: nil) }
      it "should not be valid" do
        expect(activity.valid?(:identifier_step)).to be_falsey
      end
    end

    describe "#delivery_partner_identifier" do
      context "when an activity exists with the same delivery_partner_identifier" do
        context "shares the same parent" do
          it "should be invalid" do
            fund = create(:fund_activity)
            create(:programme_activity, delivery_partner_identifier: "GB-GOV-13-001", parent: fund)

            new_programme_activity = build(:programme_activity, delivery_partner_identifier: "GB-GOV-13-001", parent: fund)

            expect(new_programme_activity).not_to be_valid
          end
        end

        context "does NOT share the same parent" do
          it "should be valid" do
            create(:fund_activity) do |fund|
              create(:programme_activity, delivery_partner_identifier: "GB-GOV-13-001", parent: fund)
            end

            other_fund = create(:fund_activity)
            new_programme_activity = build(:programme_activity, delivery_partner_identifier: "GB-GOV-13-001", parent: other_fund)

            expect(new_programme_activity).to be_valid
          end
        end
      end
    end

    describe "#roda_identifier_fragment" do
      context "for a fund" do
        let(:fund) { create(:fund_activity) }

        it "is valid if blank" do
          fund.roda_identifier_fragment = ""
          expect(fund).to be_valid(:roda_identifier_step)
        end

        it "is valid when containing certain punctuation" do
          fund.roda_identifier_fragment = "A-A_A/A\\123"
          expect(fund).to be_valid(:roda_identifier_step)
        end

        it "is not valid when containing other punctuation" do
          fund.roda_identifier_fragment = "A!A"
          expect(fund).not_to be_valid(:roda_identifier_step)
        end

        it "is valid up to 16 chars" do
          fund.roda_identifier_fragment = "A" * 16
          expect(fund).to be_valid(:roda_identifier_step)
        end

        it "is not valid above 16 chars" do
          fund.roda_identifier_fragment = "A" * 17
          expect(fund).not_to be_valid(:roda_identifier_step)
        end
      end

      context "for a programme" do
        let(:fund) { create(:fund_activity) }
        let(:programme) { create(:programme_activity, parent: fund) }

        before do
          fund.update!(roda_identifier_fragment: "A" * 6)
        end

        it "is valid if blank" do
          programme.roda_identifier_fragment = ""
          expect(programme).to be_valid(:roda_identifier_step)
        end

        it "is valid when containing certain punctuation" do
          programme.roda_identifier_fragment = "B-B_B/B\\123"
          expect(programme).to be_valid(:roda_identifier_step)
        end

        it "is not valid when containing other punctuation" do
          programme.roda_identifier_fragment = "B!B"
          expect(programme).not_to be_valid(:roda_identifier_step)
        end

        it "is valid if 'A-B' is up to 18 chars" do
          programme.roda_identifier_fragment = "B" * 11
          expect(programme).to be_valid(:roda_identifier_step)
        end

        it "is not valid if 'A-B' exceeds 18 chars" do
          programme.roda_identifier_fragment = "B" * 12
          expect(programme).not_to be_valid(:roda_identifier_step)
        end

        context "when there are other activities with similar identifiers" do
          let!(:fund_a) { create(:fund_activity, roda_identifier_fragment: "AAA") }
          let!(:programme_a) { create(:programme_activity, parent: fund_a, roda_identifier_fragment: "BBB-CCC") }

          let!(:fund_b) { create(:fund_activity, roda_identifier_fragment: "AAA-BBB") }

          it "is invalid if it has the same fragment identifier as a sibling activity" do
            programme = build(:programme_activity, parent: fund_a, roda_identifier_fragment: "BBB-CCC")
            programme.cache_roda_identifier!

            expect(programme).not_to be_valid
          end

          it "is invalid if it has the same compound identifier as a cousin activity" do
            programme = build(:programme_activity, parent: fund_b, roda_identifier_fragment: "CCC")
            programme.cache_roda_identifier!

            expect(programme).not_to be_valid
          end

          it "is valid if its identifier is different to all others" do
            programme = build(:programme_activity, parent: fund_b, roda_identifier_fragment: "VALID")
            programme.cache_roda_identifier!

            expect(programme).to be_valid
          end
        end
      end

      context "for a project" do
        let(:project) { create(:project_activity) }

        it "is valid if blank" do
          project.roda_identifier_fragment = ""
          expect(project).to be_valid(:roda_identifier_step)
        end

        it "is valid when containing certain punctuation" do
          project.roda_identifier_fragment = "C-C_C/C\\123"
          expect(project).to be_valid(:roda_identifier_step)
        end

        it "is not valid when containing other punctuation" do
          project.roda_identifier_fragment = "C!C"
          expect(project).not_to be_valid(:roda_identifier_step)
        end

        it "is valid up to 20 chars" do
          project.roda_identifier_fragment = "C" * 20
          expect(project).to be_valid(:roda_identifier_step)
        end

        it "is not valid above 20 chars" do
          project.roda_identifier_fragment = "C" * 21
          expect(project).not_to be_valid(:roda_identifier_step)
        end
      end

      context "for a third-party project" do
        let(:project) { create(:project_activity) }
        let(:third_party_project) { create(:third_party_project_activity, parent: project) }

        before do
          project.update!(roda_identifier_fragment: "C" * 10)
        end

        it "is valid if blank" do
          third_party_project.roda_identifier_fragment = ""
          expect(third_party_project).to be_valid(:roda_identifier_step)
        end

        it "is valid when containing certain punctuation" do
          third_party_project.roda_identifier_fragment = "D-D_D/D\\123"
          expect(third_party_project).to be_valid(:roda_identifier_step)
        end

        it "is not valid when containing other punctuation" do
          third_party_project.roda_identifier_fragment = "D!D"
          expect(third_party_project).not_to be_valid(:roda_identifier_step)
        end

        it "is valid if 'CD' is up to 18 chars" do
          third_party_project.roda_identifier_fragment = "D" * 11
          expect(third_party_project).to be_valid(:roda_identifier_step)
        end

        it "is not valid if 'CD' exceeds 18 chars" do
          third_party_project.roda_identifier_fragment = "D" * 12
          expect(third_party_project).not_to be_valid(:roda_identifier_step)
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

    context "when country_delivery_partners is blank/empty array on a Newton funded programme" do
      subject(:newton_fund) { build(:fund_activity, :newton) }
      subject(:activity) { build(:programme_activity, parent: newton_fund, country_delivery_partners: nil) }
      it "should not be valid" do
        expect(activity.valid?(:country_delivery_partners_step)).to be_falsey
      end
    end

    context "when country_delivery_partners is blank on a Newton funded project" do
      subject(:newton_fund) { build(:fund_activity, :newton) }
      subject(:newton_programme) { build(:programme_activity, parent: newton_fund) }
      subject(:activity) { build(:project_activity, parent: newton_programme, country_delivery_partners: nil) }
      it "should be valid" do
        expect(activity.valid?).to be_truthy
      end
    end

    context "when country_delivery_partners is blank on a non-Newton funded programme" do
      subject(:activity) { build(:programme_activity, :gcrf_funded, country_delivery_partners: nil) }
      it "should be valid" do
        expect(activity.valid?).to be_truthy
      end
    end

    context "when geography is blank" do
      subject(:activity) { build(:project_activity, geography: nil) }
      it "should not be valid" do
        expect(activity.valid?(:geography_step)).to be_falsey
      end
    end

    context "when geography is recipient_region" do
      context "and recipient_region and recipient_contry are blank" do
        subject { build(:project_activity) }
        it { should validate_presence_of(:recipient_region).on(:region_step) }
        it { should_not validate_presence_of(:recipient_country).on(:country_step) }
      end
    end

    context "when geography is recipient_country" do
      context "and recipient_region and recipient_country are blank" do
        subject { build(:project_activity, geography: :recipient_country) }
        it { should validate_presence_of(:recipient_country).on(:country_step) }
        it { should_not validate_presence_of(:recipient_region).on(:region_step) }
      end
    end

    context "when requires_additional_benefitting_countries is blank when required" do
      subject(:activity) { build(:project_activity, geography: :recipient_country, requires_additional_benefitting_countries: nil) }
      it "should not be valid" do
        expect(activity.valid?(:requires_additional_benefitting_countries_step)).to be_falsey
      end
    end

    context "when intended_beneficiaries is blank" do
      subject(:activity) { build(:project_activity, intended_beneficiaries: nil) }
      it "should not be valid" do
        expect(activity.valid?(:intended_beneficiaries_step)).to be_falsey
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
      let(:source_fund_code) { Fund::MAPPINGS["NF"] }
      subject { build(:programme_activity, source_fund_code: source_fund_code, gcrf_strategic_area: nil) }

      it { is_expected.to be_valid(:gcrf_strategic_area_step) }

      context "with a GCRF funded activity" do
        let(:source_fund_code) { Fund::MAPPINGS["GCRF"] }

        it { is_expected.to be_invalid(:gcrf_strategic_area_step) }
      end

      context "for a fund" do
        subject { build(:fund_activity, :gcrf, gcrf_strategic_area: nil) }

        it { is_expected.to be_valid(:gcrf_strategic_area_step) }
      end
    end

    context "when gcrf_strategic_area has too many values" do
      let(:source_fund_code) { Fund::MAPPINGS["NF"] }
      let(:strategic_areas) { %w[1 2 3] }
      subject { build(:programme_activity, source_fund_code: source_fund_code, gcrf_strategic_area: strategic_areas) }

      context "with a GCRF funded activity" do
        let(:source_fund_code) { Fund::MAPPINGS["GCRF"] }

        it { is_expected.to be_invalid(:gcrf_strategic_area_step) }
      end
    end

    context "when gcrf_challenge_area is blank" do
      let(:source_fund_code) { Fund::MAPPINGS["NF"] }
      subject { build(:programme_activity, source_fund_code: source_fund_code, gcrf_challenge_area: nil) }

      it { is_expected.to be_valid(:gcrf_challenge_area_step) }
      it { is_expected.to be_valid }

      context "with a GCRF funded activity" do
        let(:source_fund_code) { Fund::MAPPINGS["GCRF"] }

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

    context "when saving in the uk_dp_named_contact context" do
      context "and the activity is a fund" do
        subject { build(:project_activity, level: :fund) }
        it { should_not validate_presence_of(:uk_dp_named_contact).on(:uk_dp_named_contact_step) }
      end

      context "and the activity is a programme" do
        subject { build(:project_activity, level: :programme) }
        it { should_not validate_presence_of(:uk_dp_named_contact).on(:uk_dp_named_contact_step) }
      end

      context "when the activity is a project" do
        subject { build(:project_activity) }
        it { should validate_presence_of(:uk_dp_named_contact).on(:uk_dp_named_contact_step) }
      end

      context "when the activity is a third party project" do
        subject { build(:third_party_project_activity) }
        it { should validate_presence_of(:uk_dp_named_contact).on(:uk_dp_named_contact_step) }
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

        activity.channel_of_delivery_code = "12004"
        expect(activity).to be_invalid

        activity.channel_of_delivery_code = "11000"
        expect(activity).to be_valid
      end

      it "is required to be a BEIS-allowed code for a third party project" do
        activity = build(:third_party_project_activity, channel_of_delivery_code: nil)
        expect(activity).to be_invalid

        activity.channel_of_delivery_code = "12004"
        expect(activity).to be_invalid

        activity.channel_of_delivery_code = "11000"
        expect(activity).to be_valid
      end
    end

    describe "parent association" do
      let(:organisation) { build(:delivery_partner_organisation) }
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
  end

  describe "associations" do
    it { should belong_to(:organisation) }
    it { should have_many(:child_activities).with_foreign_key("parent_id") }
    it { should belong_to(:extending_organisation).with_foreign_key("extending_organisation_id").optional }
    it { should have_many(:implementing_organisations) }
    it { should have_many(:budgets) }
    it { should have_many(:transactions) }
    it { should have_many(:source_transfers) }
    it { should have_many(:destination_transfers) }
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

      expect(activity.has_extending_organisation?).to be true
    end
  end

  it "returns false if all extending_organisation fields are not present" do
    activity = build(:project_activity, extending_organisation: nil)

    expect(activity.has_extending_organisation?).to be false
  end

  describe "#has_implementing_organisation?" do
    it "returns true when there is one or more implementing organisationg" do
      activity = create(:project_activity_with_implementing_organisations)

      expect(activity.has_implementing_organisations?).to be true
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
          government_delivery_partner = build(:delivery_partner_organisation, organisation_type: "10")

          project = build(:project_activity, organisation: government_delivery_partner)
          expect(project.providing_organisation).to eql beis
        end
      end

      context "when the activity organisation is a non-government type" do
        it "returns BEIS" do
          beis = create(:beis_organisation)
          non_government_delivery_partner = create(:delivery_partner_organisation, organisation_type: "22")

          project = build(:project_activity, organisation: non_government_delivery_partner)
          expect(project.providing_organisation).to eql beis
        end
      end
    end

    context "when the activity is a third-party project" do
      context "when the activity organisation is a government type" do
        it "returns BEIS" do
          beis = create(:beis_organisation)
          government_delivery_partner = build(:delivery_partner_organisation, organisation_type: "10")

          project = build(:project_activity, organisation: government_delivery_partner)
          expect(project.providing_organisation).to eql beis
        end
      end

      context "when the activity organisation is a non-government type" do
        it "returns the activity organisation i.e the delivery partner" do
          non_government_delivery_partner = create(:delivery_partner_organisation, organisation_type: "22")

          third_party_project = build(:third_party_project_activity, organisation: non_government_delivery_partner)
          expect(third_party_project.providing_organisation).to eql non_government_delivery_partner
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
    let(:delivery_partner) { build_stubbed(:delivery_partner_organisation) }

    before do
      allow_any_instance_of(Activity).to receive(:service_owner).and_return(beis)
    end

    it "returns BEIS if the activity is a fund" do
      activity = build_stubbed(:fund_activity)
      expect(activity.accountable_organisation).to eql beis
    end

    it "returns BEIS if the activity is a programme" do
      activity = build_stubbed(:programme_activity, extending_organisation: delivery_partner)
      expect(activity.accountable_organisation).to eql beis
    end

    it "returns BEIS if the activity is a project" do
      activity = build_stubbed(:project_activity, extending_organisation: delivery_partner)
      expect(activity.accountable_organisation).to eql beis
    end

    it "returns BEIS if the activity is a third-party project" do
      activity = build_stubbed(:third_party_project_activity, extending_organisation: delivery_partner)
      expect(activity.accountable_organisation).to eql beis
    end

    context "with a non-government delivery partner organisation" do
      let(:delivery_partner) { build_stubbed(:delivery_partner_organisation, :non_government) }

      it "returns the delivery partner if the activity is a project" do
        activity = build_stubbed(:project_activity, extending_organisation: delivery_partner)
        expect(activity.accountable_organisation).to eql delivery_partner
      end

      it "returns the delivery partner if the activity is a third-party project" do
        activity = build_stubbed(:third_party_project_activity, extending_organisation: delivery_partner)
        expect(activity.accountable_organisation).to eql delivery_partner
      end
    end
  end

  describe "accountable_organisation_* getters" do
    let(:beis) { build_stubbed(:beis_organisation) }
    let(:delivery_partner) { build_stubbed(:delivery_partner_organisation, :non_government) }
    let(:activity) { build_stubbed(:project_activity, extending_organisation: delivery_partner) }

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

  describe "#transparency_identifier" do
    context "when the activity is a fund" do
      it "returns a composite identifier formed with the service owner" do
        fund = create(:fund_activity, roda_identifier_fragment: "GCRF-1")

        expected_identifier = [
          Organisation::SERVICE_OWNER_IATI_REFERENCE,
          fund.roda_identifier_fragment,
        ].join("-")

        expect(fund.transparency_identifier).to eql(expected_identifier)
      end
    end

    context "when the activity is a programme" do
      it "returns an identifier with the service owner, fund and programme" do
        programme = create(:programme_activity)
        fund = programme.parent

        expected_identifier = [
          Organisation::SERVICE_OWNER_IATI_REFERENCE,
          fund.roda_identifier_fragment,
          programme.roda_identifier_fragment,
        ].join("-")

        expect(programme.transparency_identifier)
          .to eql(expected_identifier)
      end
    end

    context "when the activity is a project" do
      it "returns an identifier with the service owner, fund, programme and project" do
        project = create(:project_activity)
        programme = project.parent
        fund = programme.parent

        expected_identifier = [
          Organisation::SERVICE_OWNER_IATI_REFERENCE,
          fund.roda_identifier_fragment,
          programme.roda_identifier_fragment,
          project.roda_identifier_fragment,
        ].join("-")

        expect(project.transparency_identifier)
          .to eql(expected_identifier)
      end
    end

    context "when the activity is a third-party project" do
      it "returns an identifier with the service owner, fund, programme, project and third-party project" do
        third_party_project = create(:third_party_project_activity)
        project = third_party_project.parent
        programme = project.parent
        fund = programme.parent

        project_identifier = [
          Organisation::SERVICE_OWNER_IATI_REFERENCE,
          fund.roda_identifier_fragment,
          programme.roda_identifier_fragment,
          project.roda_identifier_fragment,
        ].join("-")

        expect(third_party_project.transparency_identifier)
          .to eql("#{project_identifier}#{third_party_project.roda_identifier_fragment}")
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

  describe "#can_set_roda_identifier?" do
    let!(:fund) { create(:fund_activity, roda_identifier_fragment: "Level/A") }
    let!(:programme) { create(:programme_activity, parent: fund, roda_identifier_fragment: "Level/B") }
    let!(:project) { create(:project_activity, parent: programme, roda_identifier_fragment: nil) }

    context "for a top-level (fund) activity" do
      it "is true when the activity does not have a RODA identifier" do
        fund.roda_identifier_fragment = nil
        expect(fund.can_set_roda_identifier?).to be(true)
      end

      it "is false when the activity already has a RODA identifier" do
        expect(fund.can_set_roda_identifier?).to be(false)
      end
    end

    it "is true when all parent identifiers are present" do
      expect(project.can_set_roda_identifier?).to be(true)
    end

    it "is false if the activity has a RODA identifier" do
      project.update!(roda_identifier_fragment: "Level/C")
      expect(project.can_set_roda_identifier?).to be(false)
    end

    it "is false if the parent identifier is missing" do
      programme.update!(roda_identifier_fragment: nil)
      expect(project.can_set_roda_identifier?).to be(false)
    end

    it "is false if the grandparent identifier is missing" do
      fund.update!(roda_identifier_fragment: nil)
      expect(project.can_set_roda_identifier?).to be(false)
    end
  end

  describe "#cache_roda_identifier!" do
    let!(:fund) { create(:fund_activity, roda_identifier_fragment: "Level/A") }
    let!(:programme) { create(:programme_activity, parent: fund, roda_identifier_fragment: "Level/B") }
    let!(:project) { create(:project_activity, parent: programme, roda_identifier_fragment: "Level/C") }
    let!(:third_party_project) { create(:third_party_project_activity, parent: project, roda_identifier_fragment: "Level/D") }

    before do
      project.write_attribute(:roda_identifier_compound, nil)
      third_party_project.write_attribute(:roda_identifier_compound, nil)
    end

    it "raises an exception if roda_identifier_compound is overwritten" do
      expect { fund.cache_roda_identifier! }.to raise_error(TypeError, "Activity #{fund.id} already has a compound RODA identifier")
    end

    it "caches the compound RODA identifier on a project" do
      project.cache_roda_identifier!
      expect(project.roda_identifier_compound).to eq("Level/A-Level/B-Level/C")
    end

    it "caches the transparency identifier on a project" do
      project.cache_roda_identifier!
      expect(project.transparency_identifier).to eq("GB-GOV-13-Level-A-Level-B-Level-C")
    end

    it "caches the compound RODA identifier on a third-party project" do
      third_party_project.cache_roda_identifier!
      expect(third_party_project.roda_identifier_compound).to eq("Level/A-Level/B-Level/CLevel/D")
    end

    context "when the activity does not have a RODA identifier fragment" do
      before { project.update!(roda_identifier_fragment: nil) }

      it "raises an exception" do
        expect { project.cache_roda_identifier! }.to raise_error(TypeError)
      end
    end

    context "when the activity's parent does not have a RODA identifier fragment" do
      before { programme.update!(roda_identifier_fragment: nil) }

      it "raises an exception" do
        expect { project.cache_roda_identifier! }.to raise_error(TypeError)
      end
    end

    context "when the activity's grandparent does not have a RODA identifier fragment" do
      before { fund.update!(roda_identifier_fragment: nil) }

      it "raises an exception" do
        expect { project.cache_roda_identifier! }.to raise_error(TypeError)
      end
    end
  end

  describe "#roda_identifier" do
    let(:fund) { create(:fund_activity, roda_identifier_fragment: "GCRF") }
    let(:programme) { create(:programme_activity, parent: fund, roda_identifier_fragment: "RSDel") }
    let(:project) { create(:project_activity, parent: programme, roda_identifier_fragment: "DEL_Misc") }

    it "returns the compound RODA identifier" do
      expect(project.roda_identifier).to eq("GCRF-RSDel-DEL_Misc")
    end
  end

  describe "#actual_total_for_report_financial_quarter" do
    let(:current_quarter) { FinancialQuarter.for_date(Date.today) }

    it "returns the total of all the activity's transactions scoped to a report" do
      project = create(:project_activity, :with_report)
      report = Report.for_activity(project).first
      create(:transaction, parent_activity: project, value: 100.20, report: report, **current_quarter)
      create(:transaction, parent_activity: project, value: 50.00, report: report, **current_quarter)
      create(:transaction, parent_activity: project, value: 210, report: report, **current_quarter.pred)

      expect(project.actual_total_for_report_financial_quarter(report: report)).to eq(150.20)
    end

    it "does not include the totals for any transactions outside the report's date range" do
      project = create(:project_activity, :with_report)
      report = Report.for_activity(project).first
      create(:transaction, parent_activity: project, value: 100.20, report: report, **current_quarter.pred.pred)
      create(:transaction, parent_activity: project, value: 210, report: report, **current_quarter.pred)

      expect(project.actual_total_for_report_financial_quarter(report: report)).to eq(0)
    end
  end

  describe "#forecasted_total_for_report_financial_quarter" do
    let(:project) { create(:project_activity) }

    it "returns the activity's planned disbursement value for a report's financial quarter" do
      forecast = PlannedDisbursementHistory.new(project, financial_quarter: 3, financial_year: 2020)
      reporting_cycle = ReportingCycle.new(project, 2, 2020)

      reporting_cycle.tick
      forecast.set_value(1000.0)

      reporting_cycle.tick
      report = Report.for_activity(project).find_by(financial_quarter: 3)

      expect(project.forecasted_total_for_report_financial_quarter(report: report)).to eq(1000.00)
    end

    it "does not include totals for any planned disbursements outside the report's date range" do
      q3_forecast = PlannedDisbursementHistory.new(project, financial_quarter: 3, financial_year: 2020)
      q4_forecast = PlannedDisbursementHistory.new(project, financial_quarter: 4, financial_year: 2020)
      reporting_cycle = ReportingCycle.new(project, 2, 2020)

      reporting_cycle.tick
      q3_forecast.set_value(2000.0)
      q4_forecast.set_value(1000.0)

      reporting_cycle.tick
      report = Report.for_activity(project).find_by(financial_quarter: 3)

      expect(project.forecasted_total_for_report_financial_quarter(report: report)).to eq(2000.00)
    end

    it "only counts the latest revision value for a planned disbursement" do
      forecast = PlannedDisbursementHistory.new(project, financial_quarter: 3, financial_year: 2020)
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
    let(:forecast) { PlannedDisbursementHistory.new(project, financial_quarter: 3, financial_year: 2020) }

    it "returns the variance between #actual_total_for_report_financial_quarter and #forecasted_total_for_report_financial_quarter" do
      reporting_cycle.tick
      forecast.set_value(1500)
      reporting_cycle.tick

      report = Report.for_activity(project).find_by(financial_quarter: 3)
      create(:transaction, parent_activity: project, value: 100, report: report, date: Date.today)
      create(:transaction, parent_activity: project, value: 200, report: report, date: Date.today)

      expect(project.variance_for_report_financial_quarter(report: report)).to eq(-1200)
    end
  end

  describe "#comment_for_report" do
    it "returns the comment associated to this activity and a particular report" do
      project = create(:project_activity, :with_report)
      report = Report.for_activity(project).first
      comment = create(:comment, activity_id: project.id, report_id: report.id, comment: "Here's my comment")
      expect(project.comment_for_report(report_id: report.id)).to eq comment
      expect(project.comment_for_report(report_id: report.id).comment).to eq "Here's my comment"
    end

    it "does not return any other comments associated to this activity" do
      project = create(:project_activity, :with_report)
      report = Report.for_activity(project).first
      comment = create(:comment, activity_id: project.id, report_id: create(:report).id)
      expect(project.comment_for_report(report_id: report.id)).to_not eq comment
      expect(project.comment_for_report(report_id: report.id)).to be_nil
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
  end

  describe ".hierarchically_grouped_projects" do
    before do
      first_project = create(:project_activity, roda_identifier_fragment: "zzxx")
      create(:third_party_project_activity, roda_identifier_fragment: "ww", parent: first_project)

      _second_project = create(:project_activity, roda_identifier_fragment: "mmnn")

      third_project = create(:project_activity, roda_identifier_fragment: "aabb")
      (1..3).each do |i|
        create(:third_party_project_activity, roda_identifier_fragment: "cc#{3 - i}", parent: third_project)
      end
    end

    it "returns projects followed by their third-party project children" do
      result = Activity.all.hierarchically_grouped_projects

      expect(result.map(&:roda_identifier_fragment)).to eq(["aabb", "cc0", "cc1", "cc2", "mmnn", "zzxx", "ww"])
    end
  end

  describe "#source_fund" do
    context "for a Newton fund activity" do
      let(:activity) { build(:project_activity, source_fund_code: Fund::MAPPINGS["NF"]) }

      it "returns a Newton fund" do
        expect(activity.source_fund).to be_a(Fund)
        expect(activity.source_fund.name).to eq("Newton Fund")
        expect(activity.source_fund.id).to eq(1)
      end
    end

    context "for a GCRF activity" do
      let(:activity) { build(:project_activity, source_fund_code: Fund::MAPPINGS["GCRF"]) }

      it "returns a GCRF fund" do
        expect(activity.source_fund).to be_a(Fund)
        expect(activity.source_fund.name).to eq("GCRF")
        expect(activity.source_fund.id).to eq(2)
      end
    end
  end

  describe "#source_fund=" do
    it "sets the source fund code" do
      activity = build(:project_activity)
      activity.source_fund = Fund.new(Fund::MAPPINGS["GCRF"])
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
          programme2_third_party_project,
        ].flatten)
      end

      it "returns all the activities in a programme" do
        expect(programme1.descendants).to match_array([
          programme1_projects,
          programme1_third_party_project,
        ].flatten)

        expect(programme2.descendants).to match_array([
          programme2_projects,
          programme2_third_party_project,
        ].flatten)
      end

      it "returns all the activities in a project" do
        expect(programme1_projects[0].descendants).to match_array([
          programme1_third_party_project,
        ].flatten)
        expect(programme1_projects[1].descendants).to eq([])

        expect(programme2_projects[0].descendants).to eq([])
        expect(programme2_projects[1].descendants).to match_array([
          programme2_third_party_project,
        ].flatten)
      end
    end

    describe "#total_spend" do
      before do
        create(:transaction, value: 100, parent_activity: fund)
        create(:transaction, value: 100, parent_activity: fund, financial_year: 2020, financial_quarter: 1)

        create(:transaction, value: 100, parent_activity: programme1)
        create(:transaction, value: 100, parent_activity: programme1, financial_year: 2020, financial_quarter: 1)

        create(:transaction, value: 100, parent_activity: programme2)
        create(:transaction, value: 100, parent_activity: programme2, financial_year: 2020, financial_quarter: 1)

        create(:transaction, value: 50, parent_activity: programme1_projects[0])
        create(:transaction, value: 50, parent_activity: programme1_projects[0], financial_year: 2020, financial_quarter: 1)

        create(:transaction, value: 50, parent_activity: programme1_projects[1])
        create(:transaction, value: 50, parent_activity: programme1_projects[1], financial_year: 2020, financial_quarter: 1)

        create(:transaction, value: 100, parent_activity: programme2_projects[0])
        create(:transaction, value: 100, parent_activity: programme2_projects[0], financial_year: 2020, financial_quarter: 1)

        create(:transaction, value: 100, parent_activity: programme2_projects[1])
        create(:transaction, value: 100, parent_activity: programme2_projects[1], financial_year: 2020, financial_quarter: 1)

        create(:transaction, value: 100, parent_activity: programme1_third_party_project)
        create(:transaction, value: 100, parent_activity: programme1_third_party_project, financial_year: 2020, financial_quarter: 1)

        create(:transaction, value: 100, parent_activity: programme2_third_party_project)
        create(:transaction, value: 100, parent_activity: programme2_third_party_project, financial_year: 2020, financial_quarter: 1)
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
      def create_budget(parent_activity:, type: :direct_newton)
        create(:budget, type, value: rand(100..200), parent_activity: parent_activity)
      end

      let!(:fund_budget) { create_budget(parent_activity: fund) }
      let!(:programme1_direct_budget) { create_budget(parent_activity: programme1) }
      let!(:programme2_direct_budget) do
        [
          create_budget(parent_activity: programme2),
          create_budget(parent_activity: programme2),
        ]
      end
      let!(:programme1_project_0_direct_budget) { create_budget(parent_activity: programme1_projects[0]) }
      let!(:programme1_project_1_direct_budget) { create_budget(parent_activity: programme1_projects[1]) }
      let!(:programme2_project_0_direct_budget) { create_budget(parent_activity: programme2_projects[0]) }
      let!(:programme2_project_1_direct_budget) { create_budget(parent_activity: programme2_projects[1]) }
      let!(:programme1_project_0_third_party_project_budget) { create_budget(parent_activity: programme1_third_party_project) }
      let!(:programme2_project_1_third_party_project_budget) { create_budget(parent_activity: programme2_third_party_project) }

      let!(:external_oda_budget) { create_budget(parent_activity: programme2_projects[1], type: :external_official_development_assistance) }
      let!(:external_non_oda_budget) { create_budget(parent_activity: programme1_third_party_project, type: :external_non_official_development_assistance) }

      it "returns the total budget for a fund" do
        total_budget = [
          fund_budget,
          programme1_direct_budget,
          *programme2_direct_budget,
          programme1_project_0_direct_budget,
          programme1_project_1_direct_budget,
          programme2_project_0_direct_budget,
          programme2_project_1_direct_budget,
          programme1_project_0_third_party_project_budget,
          programme2_project_1_third_party_project_budget,
        ].sum(&:value)

        expect(fund.total_budget).to eq(total_budget)
      end

      it "returns the total budget for a programme" do
        programme1_total_budget = [
          programme1_direct_budget,
          programme1_project_0_direct_budget,
          programme1_project_1_direct_budget,
          programme1_project_0_third_party_project_budget,
        ].sum(&:value)

        programme2_total_budget = [
          *programme2_direct_budget,
          programme2_project_0_direct_budget,
          programme2_project_1_direct_budget,
          programme2_project_1_third_party_project_budget,
        ].sum(&:value)

        expect(programme1.total_budget).to eq(programme1_total_budget)
        expect(programme2.total_budget).to eq(programme2_total_budget)
      end

      it "returns the total budget for a project" do
        programme1_project_0_total_budget = [
          programme1_project_0_direct_budget,
          programme1_project_0_third_party_project_budget,
        ].sum(&:value)
        programme1_project_1_total_budget = programme1_project_1_direct_budget.value

        programme2_project_0_total_budget = programme2_project_0_direct_budget.value
        programme2_project_1_total_budget = [
          programme2_project_1_direct_budget,
          programme2_project_1_third_party_project_budget,
        ].sum(&:value)

        expect(programme1_projects[0].total_budget).to eq(programme1_project_0_total_budget)
        expect(programme1_projects[1].total_budget).to eq(programme1_project_1_total_budget)

        expect(programme2_projects[0].total_budget).to eq(programme2_project_0_total_budget)
        expect(programme2_projects[1].total_budget).to eq(programme2_project_1_total_budget)
      end
    end

    describe "#total_forecasted" do
      def create_forecast(parent_activity:)
        create(:planned_disbursement, value: rand(100..200), parent_activity: parent_activity)
      end

      let!(:fund_forecast) { create_forecast(parent_activity: fund) }
      let!(:programme1_forecast) do
        [
          create_forecast(parent_activity: programme1),
          create_forecast(parent_activity: programme1),
        ]
      end
      let!(:programme2_forecast) do
        [
          create_forecast(parent_activity: programme2),
          create_forecast(parent_activity: programme2),
        ]
      end
      let!(:programme1_project_0_forecast) { create_forecast(parent_activity: programme1_projects[0]) }
      let!(:programme1_project_1_forecast) { create_forecast(parent_activity: programme1_projects[1]) }
      let!(:programme2_project_0_forecast) { create_forecast(parent_activity: programme2_projects[0]) }
      let!(:programme2_project_1_forecast) { create_forecast(parent_activity: programme2_projects[1]) }
      let!(:programme1_project_0_third_party_project_forecast) { create_forecast(parent_activity: programme1_third_party_project) }
      let!(:programme2_project_1_third_party_project_forecast) { create_forecast(parent_activity: programme2_third_party_project) }

      it "returns the total forecasted spend for a fund" do
        total_forecasted = [
          fund_forecast,
          *programme1_forecast,
          *programme2_forecast,
          programme1_project_0_forecast,
          programme1_project_1_forecast,
          programme2_project_0_forecast,
          programme2_project_1_forecast,
          programme1_project_0_third_party_project_forecast,
          programme2_project_1_third_party_project_forecast,
        ].sum(&:value)

        expect(fund.total_forecasted).to eq(total_forecasted)
      end

      it "returns total forecasted spend for a programme" do
        programme1_total_forecasted = [
          *programme1_forecast,
          programme1_project_0_forecast,
          programme1_project_1_forecast,
          programme1_project_0_third_party_project_forecast,
        ].sum(&:value)

        programme2_total_forecasted = [
          *programme2_forecast,
          programme2_project_0_forecast,
          programme2_project_1_forecast,
          programme2_project_1_third_party_project_forecast,
        ].sum(&:value)

        expect(programme1.total_forecasted).to eq(programme1_total_forecasted)
        expect(programme2.total_forecasted).to eq(programme2_total_forecasted)
      end

      it "returns foral forecasted spend for a project" do
        programme1_project_0_forecasted = [
          programme1_project_0_forecast,
          programme1_project_0_third_party_project_forecast,
        ].sum(&:value)

        programme1_project_1_forecasted = programme1_project_1_forecast.value
        programme2_project_0_forecasted = programme2_project_0_forecast.value

        programme2_project_1_forecasted = [
          programme2_project_1_forecast,
          programme2_project_1_third_party_project_forecast,
        ].sum(&:value)

        expect(programme1_projects[0].total_forecasted).to eq(programme1_project_0_forecasted)
        expect(programme1_projects[1].total_forecasted).to eq(programme1_project_1_forecasted)
        expect(programme2_projects[0].total_forecasted).to eq(programme2_project_0_forecasted)
        expect(programme2_projects[1].total_forecasted).to eq(programme2_project_1_forecasted)
      end
    end

    describe "#own_and_descendants_transactions" do
      let!(:fund_transaction) { create(:transaction, value: 100, parent_activity: fund) }
      let!(:programme1_transaction) { create(:transaction, value: 100, parent_activity: programme1) }
      let!(:programme2_transaction) { create(:transaction, value: 100, parent_activity: programme2) }
      let!(:programme1_projects1_transaction) { create(:transaction, value: 50, parent_activity: programme1_projects[0]) }
      let!(:programme1_projects2_transaction) { create(:transaction, value: 50, parent_activity: programme1_projects[1]) }
      let!(:programme2_projects1_transaction) { create(:transaction, value: 100, parent_activity: programme2_projects[0]) }
      let!(:programme2_projects2_transaction) { create(:transaction, value: 100, parent_activity: programme2_projects[1]) }
      let!(:programme1_tpp_transaction) { create(:transaction, value: 100, parent_activity: programme1_third_party_project) }
      let!(:programme2_tpp_transaction) { create(:transaction, value: 100, parent_activity: programme2_third_party_project) }

      it "returns all the transactions belonging to the activity and to the descendant activities" do
        expect(fund.own_and_descendants_transactions.pluck(:id)).to match_array([
          fund_transaction.id,
          programme1_transaction.id,
          programme2_transaction.id,
          programme1_projects1_transaction.id,
          programme1_projects2_transaction.id,
          programme2_projects1_transaction.id,
          programme2_projects2_transaction.id,
          programme1_tpp_transaction.id,
          programme2_tpp_transaction.id,
        ])
      end
    end

    describe "#reportable_transactions_for_level" do
      context "when the activity is a programme" do
        it "sums up the transactions of the activity and child activities by financial quarter" do
          organisation = create(:delivery_partner_organisation)
          programme = create(:programme_activity, :with_transparency_identifier, extending_organisation: organisation, delivery_partner_identifier: "IND-ENT-IFIER")
          projects = create_list(:project_activity, 2, parent: programme)
          third_party_project = create(:third_party_project_activity, parent: projects[0])

          create(:transaction, value: 1000, parent_activity: programme, financial_year: 2018, financial_quarter: 1)
          create(:transaction, value: 1000, parent_activity: programme, financial_year: 2018, financial_quarter: 2)
          create(:transaction, value: 500, parent_activity: projects[0], financial_year: 2018, financial_quarter: 1)
          create(:transaction, value: 500, parent_activity: projects[0], financial_year: 2020, financial_quarter: 1)

          create(:transaction, value: 500, parent_activity: projects[1], financial_year: 2018, financial_quarter: 1)
          create(:transaction, value: 500, parent_activity: projects[1], financial_year: 2020, financial_quarter: 1)

          create(:transaction, value: 200, parent_activity: third_party_project, financial_year: 2018, financial_quarter: 1)
          create(:transaction, value: 200, parent_activity: third_party_project, financial_year: 2020, financial_quarter: 1)

          reportable_transactions = programme.reportable_transactions_for_level
          expect(reportable_transactions.map(&:value)).to eql([1200, 1000, 2200])
          expect(reportable_transactions.map(&:date)).to eql([FinancialQuarter.new(2020, 1).end_date, FinancialQuarter.new(2018, 2).end_date, FinancialQuarter.new(2018, 1).end_date])
        end
      end

      context "when the activity is a project or third-party project" do
        it "returns all the transactions with that activity only" do
          organisation = create(:delivery_partner_organisation)
          project = create(:project_activity, :with_transparency_identifier, organisation: organisation)
          third_party_project = create(:third_party_project_activity, parent: project, organisation: organisation)

          project_transaction_1 = create(:transaction, value: 1000, parent_activity: project)
          project_transaction_2 = create(:transaction, value: 1000, parent_activity: project)
          project_transaction_3 = create(:transaction, value: 500, parent_activity: project)
          project_transaction_4 = create(:transaction, value: 500, parent_activity: project)

          third_party_project_transaction = create(:transaction, value: 500, parent_activity: third_party_project)

          expect(project.reportable_transactions_for_level).to match_array([project_transaction_1, project_transaction_2, project_transaction_3, project_transaction_4])
          expect(third_party_project.reportable_transactions_for_level).to match_array([third_party_project_transaction])
        end
      end
    end
  end
end
