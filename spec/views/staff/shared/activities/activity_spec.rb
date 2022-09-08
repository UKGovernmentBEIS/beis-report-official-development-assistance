RSpec.describe "staff/shared/activities/_activity" do
  let(:policy_stub) { ActivityPolicy.new(user, activity) }
  let(:user) { build(:partner_organisation_user) }
  let(:activity) { build(:programme_activity) }
  let(:activity_presenter) { ActivityPresenter.new(activity) }
  let(:country_partner_orgs) { ["ACME Inc"] }
  let(:body) { Capybara.string(rendered) }

  before do
    without_partial_double_verification do
      allow(view).to receive(:activity_presenter).and_return(activity_presenter)
      allow(view).to receive(:current_user).and_return(user)
      allow(view).to receive(:policy).with(any_args).and_return(policy_stub)
      allow(view).to receive(:activity_step_path).and_return("This path isn't important")
      allow(view).to receive(:edit_activity_redaction_path).and_return("This path isn't important")
      allow(view).to receive(:organisation_activity_path).and_return("This path isn't important")
    end

    render
  end

  context "With a GCRF fund" do
    context "when the activity is a programme activity" do
      let(:activity) { build(:programme_activity, :gcrf_funded) }

      it { is_expected.to show_basic_details }
      it { is_expected.to show_gcrf_specific_details }
    end

    context "when the activity is a project activity" do
      let(:activity) { build(:project_activity, :gcrf_funded) }

      it { is_expected.to show_basic_details }
      it { is_expected.to show_project_details }
      it { is_expected.to show_gcrf_specific_details }
    end

    context "when the activity is a third party project activity" do
      let(:activity) { build(:third_party_project_activity, :gcrf_funded) }

      it { is_expected.to show_basic_details }
      it { is_expected.to show_project_details }
      it { is_expected.to show_gcrf_specific_details }
    end
  end

  context "With a Newton fund" do
    context "when the activity is a programme activity" do
      let(:activity) { build(:programme_activity, :newton_funded, country_delivery_partners: country_partner_orgs) }

      it { is_expected.to show_basic_details }
    end

    context "when the activity is a project activity" do
      let(:activity) { build(:project_activity, :newton_funded, country_delivery_partners: country_partner_orgs) }

      it { is_expected.to show_basic_details }
      it { is_expected.to show_project_details }
      it { is_expected.to show_newton_specific_details }
    end

    context "when the activity is a third party project activity" do
      let(:activity) { build(:third_party_project_activity, :newton_funded, country_delivery_partners: country_partner_orgs) }

      it { is_expected.to show_basic_details }
      it { is_expected.to show_project_details }
      it { is_expected.to show_newton_specific_details }
    end
  end

  context "showing the publish to iati field" do
    context "when redact_from_iati is false" do
      let(:policy_stub) { double("policy", update?: true, redact_from_iati?: false) }

      it { is_expected.to_not show_the_publish_to_iati_field }
    end

    context "when redact_from_iati is true" do
      let(:policy_stub) { double("policy", update?: true, redact_from_iati?: true) }

      it { is_expected.to show_the_publish_to_iati_field }
    end
  end

  context "when signed in as a BEIS user" do
    let(:user) { build(:beis_user) }

    context "when the activity is a fund activity" do
      let(:activity) { build(:fund_activity, organisation: user.organisation) }

      it "does not show the parent field" do
        expect(rendered).not_to have_content(t("activerecord.attributes.activity.parent"))
      end

      context "when a title attribute is present" do
        let(:activity) { build(:fund_activity, title: "Some title", organisation: user.organisation) }

        it "the call to action is 'Edit'" do
          expect(body.find(".title a")).to have_content(t("default.link.edit"))
        end
      end

      context "when an activity attribute is not present" do
        let(:activity) { build(:fund_activity, title: nil, organisation: user.organisation) }

        it "the call to action is 'Add'" do
          expect(body.find(".title a")).to have_content(t("default.link.add"))
        end
      end

      context "when the activity only has an identifier" do
        let(:activity) { build(:fund_activity, :at_purpose_step, organisation: user.organisation) }

        it "only shows the add link on the next step" do
          expect(body.find(".identifier")).to_not have_content(t("default.link.edit"))
          expect(body.find(".sector")).to_not have_content(t("default.link.add"))
          expect(body.find(".title a")).to have_content(t("default.link.add"))
        end
      end
    end
  end

  context "when the activity is programme level activity" do
    let(:activity) { build(:programme_activity) }

    it "does not show the Channel of delivery code field" do
      expect(rendered).to_not have_content(t("activerecord.attributes.activity.channel_of_delivery_code"))
    end

    it { is_expected.to_not show_the_edit_add_actions }
  end

  context "when the activity is a project level activity" do
    let(:activity) { build(:project_activity, organisation: user.organisation) }

    it { is_expected.to_not show_the_edit_add_actions }

    context "and the policy allows a user to upate" do
      let(:policy_stub) { double("policy", update?: true, redact_from_iati?: false) }

      it { is_expected.to show_the_edit_add_actions }

      it "does not show an edit link for the partner organisation identifier" do
        expect(body.find(".identifier")).to_not have_content(t("default.link.edit"))
      end

      context "when the project does not have a partner organisation identifier" do
        let(:activity) { build(:project_activity, partner_organisation_identifier: nil, organisation: user.organisation) }

        scenario "shows an edit link for the partner organisation identifier" do
          expect(body.find(".identifier")).to have_content(t("default.link.add"))
        end
      end

      context "when the project has a RODA identifier" do
        let(:activity) { build(:project_activity, organisation: user.organisation, roda_identifier: "A-RODA-ID") }

        it "does not show an edit or add link for the RODA identifier" do
          expect(body.find(".roda_identifier")).to_not have_content(t("default.link.add"))
          expect(body.find(".roda_identifier")).to_not have_content(t("default.link.add"))
        end
      end

      it "shows a link to edit the UK PO named contact" do
        expect(body.find(".uk_dp_named_contact")).to have_content(t("default.link.edit"))
      end
    end
  end

  describe "Benefitting region" do
    let(:activity) { build(:programme_activity, benefitting_countries: benefitting_countries) }

    context "when the activity has benefitting countries" do
      subject { body.find(".benefitting_region") }

      let(:benefitting_countries) { ["DZ", "LY"] }
      let(:expected_region) { BenefittingCountry.find_by_code("DZ").regions.last }

      it { is_expected.to have_content(expected_region.name) }
      it { is_expected.to_not show_the_edit_add_actions }
    end

    context "when the activity has no benefitting countries" do
      subject { body }

      let(:benefitting_countries) { [] }

      it { is_expected.to have_css(".benefitting_region") }
    end
  end

  describe "legacy geography recipient_region, recipient_country and intended_beneficiaries" do
    context "when there is a value" do
      let(:activity) {
        build(
          :programme_activity,
          recipient_region: "298",
          recipient_country: "UG",
          intended_beneficiaries: ["UG"]
        )
      }

      it "is shown at all times and has a helpful 'read only' label" do
        expect(body.find(".recipient_region .govuk-summary-list__value")).to have_content("Africa, regional")
        expect(body.find(".recipient_region .govuk-summary-list__key")).to have_content("Legacy field: not editable")

        expect(body.find(".recipient_country .govuk-summary-list__value")).to have_content("Uganda")
        expect(body.find(".recipient_country .govuk-summary-list__key")).to have_content("Legacy field: not editable")

        expect(body.find(".intended_beneficiaries .govuk-summary-list__value")).to have_content("Uganda")
        expect(body.find(".intended_beneficiaries .govuk-summary-list__key")).to have_content("Legacy field: not editable")
      end
    end

    context "when there is NOT a value" do
      let(:activity) {
        build(
          :programme_activity,
          recipient_region: nil,
          recipient_country: nil,
          intended_beneficiaries: []
        )
      }

      it "is shown at all times and has a helpful 'read only' label" do
        expect(body.find(".recipient_region .govuk-summary-list__key")).to have_content("Legacy field: not editable")
        expect(body.find(".recipient_country .govuk-summary-list__key")).to have_content("Legacy field: not editable")
        expect(body.find(".intended_beneficiaries .govuk-summary-list__key")).to have_content("Legacy field: not editable")
      end
    end
  end

  RSpec::Matchers.define :show_the_edit_add_actions do
    match do
      expect(rendered).to have_link(t("default.link.edit"))
      expect(rendered).to have_link(t("default.link.add"))
    end
  end

  RSpec::Matchers.define :show_the_publish_to_iati_field do
    match do |actual|
      expect(rendered).to have_content(t("summary.label.activity.publish_to_iati.label"))
    end
  end

  RSpec::Matchers.define :show_basic_details do
    match do |actual|
      expect(rendered).to have_content activity_presenter.partner_organisation_identifier
      expect(rendered).to have_content activity_presenter.title
      expect(rendered).to have_content activity_presenter.description
      expect(rendered).to have_content activity_presenter.sector
      expect(rendered).to have_content activity_presenter.programme_status
      expect(rendered).to have_content activity_presenter.objectives

      within(".govuk-summary-list__row.collaboration_type") do
        expect(rendered).to have_content activity_presenter.collaboration_type
      end

      expect(rendered).to have_content activity_presenter.gdi
      expect(rendered).to have_content activity_presenter.aid_type

      expect(rendered).to have_content activity_presenter.aid_type

      expect(rendered).to have_content activity_presenter.oda_eligibility

      expect(rendered).to have_content activity_presenter.planned_start_date
      expect(rendered).to have_content activity_presenter.planned_end_date
    end

    description do
      "show basic details for an activity"
    end
  end

  RSpec::Matchers.define :show_project_details do
    match do |actual|
      expect(rendered).to have_content activity_presenter.call_present
      expect(rendered).to have_content activity_presenter.total_applications
      expect(rendered).to have_content activity_presenter.total_awards

      within(".policy_marker_gender") do
        expect(rendered).to have_content activity_presenter.policy_marker_gender
      end
      within(".policy_marker_climate_change_adaptation") do
        expect(rendered).to have_content activity_presenter.policy_marker_climate_change_adaptation
      end
      within(".policy_marker_climate_change_mitigation") do
        expect(rendered).to have_content activity_presenter.policy_marker_climate_change_mitigation
      end
      within(".policy_marker_biodiversity") do
        expect(rendered).to have_content activity_presenter.policy_marker_biodiversity
      end
      within(".policy_marker_desertification") do
        expect(rendered).to have_content activity_presenter.policy_marker_desertification
      end
      within(".policy_marker_disability") do
        expect(rendered).to have_content activity_presenter.policy_marker_disability
      end
      within(".policy_marker_disaster_risk_reduction") do
        expect(rendered).to have_content activity_presenter.policy_marker_disaster_risk_reduction
      end
      within(".policy_marker_nutrition") do
        expect(rendered).to have_content activity_presenter.policy_marker_nutrition
      end

      expect(rendered).to have_content t("activerecord.attributes.activity.channel_of_delivery_code")
      expect(rendered).to have_content activity_presenter.channel_of_delivery_code

      expect(rendered).to have_content activity_presenter.oda_eligibility_lead
      expect(rendered).to have_content activity_presenter.uk_dp_named_contact

      expect(rendered).to have_content activity_presenter.call_open_date
      expect(rendered).to have_content activity_presenter.call_close_date
    end

    description do
      "show project-specific details for an activity"
    end
  end

  RSpec::Matchers.define :show_newton_specific_details do
    match do |actual|
      expect(rendered).to have_css(".govuk-summary-list__row.country_delivery_partners")
      activity_presenter.country_delivery_partners.each do |delivery_partner|
        expect(rendered).to have_content(delivery_partner)
      end
      expect(rendered).to have_content activity_presenter.fund_pillar
    end

    description do
      "show Newton activity specific details for an activity"
    end
  end

  RSpec::Matchers.define :show_gcrf_specific_details do
    match do |actual|
      expect(rendered).to have_css(".govuk-summary-list__row.gcrf_strategic_area")
      expect(rendered).to have_css(".govuk-summary-list__row.gcrf_challenge_area")

      expect(rendered).to have_content(activity_presenter.gcrf_strategic_area)
      expect(rendered).to have_content(activity_presenter.gcrf_challenge_area)
    end

    description do
      "show GCRF activity specific details for an activity"
    end
  end
end
