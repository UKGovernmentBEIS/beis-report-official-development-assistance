RSpec.describe "staff/shared/activities/_activity" do
  let(:policy_stub) { double("policy", update?: true, redact_from_iati?: false) }
  let(:user) { build(:delivery_partner_user) }
  let(:activity_presenter) { ActivityPresenter.new(activity) }
  let(:country_delivery_partners) { ["ACME Inc"] }

  before do
    without_partial_double_verification do
      allow(view).to receive(:activity_presenter).and_return(activity_presenter)
      allow(view).to receive(:current_user).and_return(user)
      allow(view).to receive(:policy).with(any_args).and_return(policy_stub)
      allow(activity_presenter).to receive(:id) { 123 }
    end

    render
  end

  context "With a GCRF fund" do
    context "when the activity is a programme activity" do
      let(:activity) { create(:programme_activity, :gcrf_funded) }

      it { is_expected.to show_basic_details }
      it { is_expected.to show_gcrf_specific_details }
    end

    context "when the activity is a project activity" do
      let(:activity) { create(:project_activity, :gcrf_funded) }

      it { is_expected.to show_basic_details }
      it { is_expected.to show_project_details }
      it { is_expected.to show_gcrf_specific_details }
    end

    context "when the activity is a third party project activity" do
      let(:activity) { create(:third_party_project_activity, :gcrf_funded) }

      it { is_expected.to show_basic_details }
      it { is_expected.to show_project_details }
      it { is_expected.to show_gcrf_specific_details }
    end
  end

  context "With a Newton fund" do
    context "when the activity is a programme activity" do
      let(:activity) { create(:programme_activity, :newton_funded, country_delivery_partners: country_delivery_partners) }

      it { is_expected.to show_basic_details }
    end

    context "when the activity is a project activity" do
      let(:activity) { create(:project_activity, :newton_funded, country_delivery_partners: country_delivery_partners) }

      it { is_expected.to show_basic_details }
      it { is_expected.to show_project_details }
      it { is_expected.to show_newton_specific_details }
    end

    context "when the activity is a third party project activity" do
      let(:activity) { create(:third_party_project_activity, :newton_funded, country_delivery_partners: country_delivery_partners) }

      it { is_expected.to show_basic_details }
      it { is_expected.to show_project_details }
      it { is_expected.to show_newton_specific_details }
    end
  end

  RSpec::Matchers.define :show_basic_details do
    match do |actual|
      expect(rendered).to have_content activity_presenter.delivery_partner_identifier
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

      expect(rendered).to have_content t("summary.label.activity.channel_of_delivery_code")
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
