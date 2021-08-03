# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActivityPresenter do
  RSpec.shared_examples "a code translator" do |field, args, field_type|
    let(:field) { field }
    let(:args) { args.reverse_merge(source: "iati") }
    let(:field_type) { field_type }

    def cast_code_to_field(code)
      return code if field_type.nil?
      return code.to_i if field_type == "Integer"
      return [code] if field_type == "Array"
    end

    it "has translations for all of the codes" do
      Codelist.new(**args).each do |code|
        activity = build(:project_activity)
        code = cast_code_to_field(code["code"])
        activity.write_attribute(field, code)

        expect(described_class.new(activity).send(field)).to_not match(/translation missing/)
      end
    end
  end

  describe "#aid_type" do
    it_behaves_like "a code translator", "aid_type", {type: "aid_type"}

    context "when the aid_type exists" do
      it "returns the locale value for the code" do
        activity = build(:project_activity, aid_type: "a01")
        result = described_class.new(activity).aid_type
        expect(result).to eql("General budget support")
      end

      it "returns the locale value when the code is upper case" do
        activity = build(:project_activity, aid_type: "A01")
        result = described_class.new(activity).aid_type
        expect(result).to eql("General budget support")
      end
    end

    context "when the activity does not have an aid_type set" do
      it "returns nil" do
        activity = build(:project_activity, :at_identifier_step)
        result = described_class.new(activity)
        expect(result.aid_type).to be_nil
      end
    end
  end

  describe "#aid_type_with_code" do
    context "when the aid_type exists" do
      it "returns the locale value for the code with the code in brackets" do
        activity = build(:project_activity, aid_type: "A01")
        result = described_class.new(activity).aid_type_with_code
        expect(result).to eql("General budget support (A01)")
      end
    end

    context "when the activity does not have an aid_type set" do
      it "returns nil" do
        activity = build(:project_activity, :at_identifier_step)
        result = described_class.new(activity)
        expect(result.aid_type_with_code).to be_nil
      end
    end
  end

  describe "#covid19_related" do
    it_behaves_like "a code translator", "covid19_related", {type: "covid19_related_research", source: "beis"}

    it "returns the locale value for the code" do
      activity = build(:project_activity, covid19_related: 3)
      result = described_class.new(activity).covid19_related
      expect(result).to eql("New activity that will somewhat focus on COVID-19")
    end
  end

  describe "#sector" do
    it_behaves_like "a code translator", "sector", {type: "sector"}

    context "when the sector exists" do
      it "returns the locale value for the code" do
        activity = build(:project_activity, sector: "11110")
        result = described_class.new(activity).sector
        expect(result).to eql("Education policy and administrative management")
      end
    end

    context "when the activity does not have a sector set" do
      it "returns nil" do
        activity = build(:project_activity, sector: nil)
        result = described_class.new(activity)
        expect(result.sector).to be_nil
      end
    end
  end

  describe "#sector_with_code" do
    context "when the sector exists" do
      it "returns the locale value for the code with the code in brackets" do
        activity = build(:project_activity, sector: "11110")
        result = described_class.new(activity).sector_with_code
        expect(result).to eql("Education policy and administrative management (11110)")
      end
    end

    context "when the activity does not have a sector set" do
      it "returns nil" do
        activity = build(:project_activity, sector: nil)
        result = described_class.new(activity)
        expect(result.sector_with_code).to be_nil
      end
    end
  end

  describe "#call_present" do
    context "when there is a call" do
      it "returns the locale value for this option" do
        activity = build(:project_activity, call_present: "true")
        result = described_class.new(activity)
        expect(result.call_present).to eq("Yes")
      end
    end

    context "when there is not a call" do
      it "returns the locale value for this option" do
        activity = build(:project_activity, call_present: "false")
        result = described_class.new(activity)
        expect(result.call_present).to eq("No")
      end
    end
  end

  describe "#call_open_date" do
    context "when the call open date exists" do
      it "returns a human readable date" do
        activity = build(:project_activity, call_open_date: "2020-02-20")
        result = described_class.new(activity).call_open_date
        expect(result).to eq("20 Feb 2020")
      end
    end

    context "when the planned start date does not exist" do
      it "returns nil" do
        activity = build(:project_activity, call_open_date: nil)
        result = described_class.new(activity)
        expect(result.call_open_date).to be_nil
      end
    end
  end

  describe "#call_close_date" do
    context "when the call close date exists" do
      it "returns a human readable date" do
        activity = build(:project_activity, call_close_date: "2020-06-23")
        result = described_class.new(activity).call_close_date
        expect(result).to eq("23 Jun 2020")
      end
    end

    context "when the planned close date does not exist" do
      it "returns nil" do
        activity = build(:project_activity, call_close_date: nil)
        result = described_class.new(activity)
        expect(result.call_close_date).to be_nil
      end
    end
  end

  describe "#programme_status" do
    it_behaves_like "a code translator", "programme_status", {type: "programme_status", source: "beis"}

    context "when the programme status exists" do
      it "returns the locale value for the code" do
        activity = build(:project_activity, programme_status: "spend_in_progress")
        result = described_class.new(activity).programme_status
        expect(result).to eql("Spend in progress")
      end
    end

    context "when the activity does not have a programme status set" do
      it "returns nil" do
        activity = build(:project_activity, programme_status: nil)
        result = described_class.new(activity)
        expect(result.programme_status).to be_nil
      end
    end
  end

  describe "#planned_start_date" do
    context "when the planned start date exists" do
      it "returns a human readable date" do
        activity = build(:project_activity, planned_start_date: "2020-02-25")
        result = described_class.new(activity).planned_start_date
        expect(result).to eql("25 Feb 2020")
      end
    end

    context "when the planned start date does not exist" do
      it "returns nil" do
        activity = build(:project_activity, planned_start_date: nil)
        result = described_class.new(activity)
        expect(result.planned_start_date).to be_nil
      end
    end
  end

  describe "#planned_end_date" do
    context "when the planned end date exists" do
      it "returns a human readable date" do
        activity = build(:project_activity, planned_end_date: "2021-04-03")
        result = described_class.new(activity).planned_end_date
        expect(result).to eql("3 Apr 2021")
      end
    end

    context "when the planned end date does not exist" do
      it "returns nil" do
        activity = build(:project_activity, planned_end_date: nil)
        result = described_class.new(activity)
        expect(result.planned_end_date).to be_nil
      end
    end
  end

  describe "#actual_start_date" do
    context "when the actual start date exists" do
      it "returns a human readable date" do
        activity = build(:project_activity, actual_start_date: "2020-11-06")
        result = described_class.new(activity).actual_start_date
        expect(result).to eql("6 Nov 2020")
      end
    end

    context "when the actual start date does not exist" do
      it "returns nil" do
        activity = build(:project_activity, actual_start_date: nil)
        result = described_class.new(activity)
        expect(result.actual_start_date).to be_nil
      end
    end
  end

  describe "#actual_end_date" do
    context "when the actual end date exists" do
      it "returns a human readable date" do
        activity = build(:project_activity, actual_end_date: "2029-05-27")
        result = described_class.new(activity).actual_end_date
        expect(result).to eql("27 May 2029")
      end
    end

    context "when the actual end date does not exist" do
      it "returns nil" do
        activity = build(:project_activity, actual_end_date: nil)
        result = described_class.new(activity)
        expect(result.actual_end_date).to be_nil
      end
    end
  end

  describe "#benefitting_countries" do
    it_behaves_like "a code translator", "benefitting_countries", {type: "recipient_country"}, "Array"

    context "when there are benefitting countries" do
      it "returns the locale value for the codes of the countries" do
        activity = build(:project_activity, benefitting_countries: ["AR", "EC", "BR"])
        result = described_class.new(activity).benefitting_countries
        expect(result).to eql("Argentina, Ecuador, and Brazil")
      end
    end
  end

  describe "#recipient_region" do
    it_behaves_like "a code translator", "recipient_region", {type: "recipient_region"}

    context "when the aid_type recipient_region" do
      it "returns the locale value for the code" do
        activity = build(:project_activity, recipient_region: "489")
        result = described_class.new(activity).recipient_region
        expect(result).to eql("South America, regional")
      end
    end

    context "when the activity does not have a recipient_region set" do
      it "returns nil" do
        activity = build(:project_activity, recipient_region: nil)
        result = described_class.new(activity)
        expect(result.recipient_region).to be_nil
      end
    end
  end

  describe "#recipient_country" do
    it_behaves_like "a code translator", "recipient_country", {type: "recipient_country"}

    context "when there is a recipient_country" do
      it "returns the locale value for the code" do
        activity = build(:project_activity, recipient_country: "CL")
        result = described_class.new(activity).recipient_country
        expect(result).to eq t("activity.recipient_country.#{activity.recipient_country}")
      end
    end

    context "when the activity does not have a recipient_country set" do
      it "returns nil" do
        activity = build(:project_activity, recipient_country: nil)
        result = described_class.new(activity)
        expect(result.recipient_country).to be_nil
      end
    end
  end

  describe "#requires_additional_benefitting_countries" do
    context "when requires_additional_benefitting_countries exists" do
      it "returns the locale value for this option" do
        activity = build(:project_activity, requires_additional_benefitting_countries: "true")
        result = described_class.new(activity)
        expect(result.requires_additional_benefitting_countries).to eq("Yes")
      end
    end

    context "when requires_additional_benefitting_countries is not required" do
      it "returns the locale value for this option" do
        activity = build(:project_activity, requires_additional_benefitting_countries: "false")
        result = described_class.new(activity)
        expect(result.requires_additional_benefitting_countries).to eq("No")
      end
    end
  end

  describe "#intended_beneficiaries" do
    it_behaves_like "a code translator", "intended_beneficiaries", {type: "recipient_country"}, "Array"

    context "when there are other benefitting countries" do
      it "returns the locale value for the codes of the countries" do
        activity = build(:project_activity, intended_beneficiaries: ["AR", "EC", "BR"])
        result = described_class.new(activity).intended_beneficiaries
        expect(result).to eql("Argentina, Ecuador, and Brazil")
      end
    end
  end

  describe "#gdi" do
    it_behaves_like "a code translator", "gdi", {type: "gdi"}

    context "when gdi exists" do
      it "returns the locale value for the code" do
        activity = build(:project_activity, gdi: "3")
        result = described_class.new(activity).gdi
        expect(result).to eql("Yes - China and India")
      end
    end

    context "when the activity does not have a gdi set" do
      it "returns nil" do
        activity = build(:project_activity, gdi: nil)
        result = described_class.new(activity)
        expect(result.gdi).to be_nil
      end
    end
  end

  describe "#collaboration_type" do
    it_behaves_like "a code translator", "collaboration_type", {type: "collaboration_type"}

    context "when collaboration_type exists" do
      it "returns the locale value for the code" do
        activity = build(:project_activity, collaboration_type: "1")
        result = described_class.new(activity).collaboration_type
        expect(result).to eql("Bilateral")
      end
    end

    context "when the activity does not have a collaboration_type set" do
      it "returns nil" do
        activity = build(:project_activity, collaboration_type: nil)
        result = described_class.new(activity)
        expect(result.collaboration_type).to be_nil
      end
    end
  end

  describe "#flow" do
    it "returns the locale value for the default ODA code" do
      activity = build(:project_activity)
      result = described_class.new(activity).flow
      expect(result).to eql("ODA")
    end
  end

  describe "#flow_with_code" do
    it "returns the default flow string & code number" do
      fund = create(:project_activity)
      expect(described_class.new(fund).flow_with_code).to eql("ODA (10)")
    end
  end

  describe "#policy_marker_gender" do
    it_behaves_like "a code translator", "policy_marker_gender", {type: "policy_significance", source: "beis"}, "Integer"

    context "when gender exists" do
      it "returns the locale value for the code" do
        activity = build(:project_activity, policy_marker_gender: "not_targeted")
        result = described_class.new(activity).policy_marker_gender
        expect(result).to eql("Not targeted")
      end
    end

    context "when the value is the BEIS custom value" do
      it "returns the locale value for the custom code" do
        activity = build(:project_activity, policy_marker_gender: "not_assessed")
        result = described_class.new(activity).policy_marker_gender
        expect(result).to eql("Not assessed")
      end
    end

    context "when the activity does not have a gender set" do
      it "returns nil" do
        activity = build(:project_activity, policy_marker_gender: nil)
        result = described_class.new(activity)
        expect(result.policy_marker_gender).to be_nil
      end
    end
  end

  describe "#sustainable_development_goals_apply" do
    let(:activity) { build(:project_activity, sdgs_apply: sdgs_apply) }

    subject { described_class.new(activity).sustainable_development_goals_apply }

    context "when sdgs_apply is true" do
      let(:sdgs_apply) { true }

      it { is_expected.to eq("Yes") }
    end

    context "when sdgs_apply is false" do
      let(:sdgs_apply) { false }

      it { is_expected.to eq("No") }
    end
  end

  describe "#sustainable_development_goals" do
    it "returns 'Not applicable' when the user selects that SDGs do not apply (sdgs_apply is false)" do
      activity = build(:project_activity, sdgs_apply: false)
      result = described_class.new(activity).sustainable_development_goals

      expect(result).to eq("Not applicable")
    end

    it "leaves the field blank when the SDG form step has not been filled yet" do
      activity = build(:project_activity, sdgs_apply: false, form_state: nil)
      result = described_class.new(activity).sustainable_development_goals

      expect(result).to be_nil
    end

    it "when there is a single SDG, return its name" do
      activity = build(:project_activity, sdgs_apply: true, sdg_1: 5)
      result = described_class.new(activity)

      items = Nokogiri::HTML(result.sustainable_development_goals).css("ol > li")
      expect(items[0].text).to eql "Gender Equality"
    end

    it "when there are multiple SDGs, return their names, separated by a slash" do
      activity = build(:project_activity, sdgs_apply: true, sdg_1: 5, sdg_2: 1)
      result = described_class.new(activity)

      items = Nokogiri::HTML(result.sustainable_development_goals).css("ol > li")
      expect(items[0].text).to eql "Gender Equality"
      expect(items[1].text).to eql "No Poverty"
    end

    it "when there are no SDGs return nil" do
      activity = build(:project_activity, sdgs_apply: true, sdg_1: nil, sdg_2: nil, sdg_3: nil)
      result = described_class.new(activity)

      expect(result.sustainable_development_goals).to be_nil
    end
  end

  describe "#gcrf_strategic_area" do
    it "returns the code list description values for the stored integers" do
      activity = build(:project_activity, gcrf_strategic_area: %w[17A RF])
      result = described_class.new(activity)

      expect(result.gcrf_strategic_area).to eql "UKRI Collective Fund (2017 allocation) and Academies Collective Fund: Resilient Futures"
    end
  end

  describe "#gcrf_challenge_area" do
    it_behaves_like "a code translator", "gcrf_challenge_area", {type: "gcrf_challenge_area", source: "beis"}, "Integer"

    it "returns the locale value for the stored integer" do
      activity = build(:project_activity, gcrf_challenge_area: 2)
      result = described_class.new(activity)

      expect(result.gcrf_challenge_area).to eql "Sustainable health and well being"
    end
  end

  describe "#oda_eligibility" do
    it_behaves_like "a code translator", "oda_eligibility", {type: "oda_eligibility", source: "beis"}, "Integer"

    context "when the activity is ODA eligible" do
      it "returns the locale value for this option" do
        activity = build(:project_activity, oda_eligibility: 1)
        result = described_class.new(activity)
        expect(result.oda_eligibility).to eq("Eligible")
      end
    end

    context "when the activity is no longer ODA eligible" do
      it "returns the locale value for this option" do
        activity = build(:project_activity, oda_eligibility: 2)
        result = described_class.new(activity)
        expect(result.oda_eligibility).to eq("No longer eligible")
      end
    end

    context "when the activity was never ODA eligible" do
      it "returns the locale value for this option" do
        activity = build(:project_activity, oda_eligibility: 0)
        result = described_class.new(activity)
        expect(result.oda_eligibility).to eq("No - was never eligible")
      end
    end
  end

  describe "#call_to_action" do
    it "returns 'edit' if the desired attribute is present" do
      activity = build(:project_activity, title: "My title")
      expect(described_class.new(activity).call_to_action(:title)).to eql("edit")
    end

    it "returns 'edit' if the desired attribute is 'false'" do
      activity = build(:project_activity, fstc_applies: false)
      expect(described_class.new(activity).call_to_action(:title)).to eql("edit")
    end

    it "returns 'add' if the desired attribute is not present" do
      activity = build(:project_activity, title: nil)
      expect(described_class.new(activity).call_to_action(:title)).to eql("add")
    end
  end

  describe "#display_title" do
    context "when the title is nil" do
      it "returns a default display_title" do
        activity = create(:project_activity, :at_purpose_step, title: nil)
        expect(described_class.new(activity).display_title).to eql("Untitled (#{activity.id})")
      end
    end

    context "when the title is present" do
      it "returns the title" do
        activity = build(:project_activity)
        expect(described_class.new(activity).display_title).to eql(activity.title)
      end
    end
  end

  describe "#parent_title" do
    context "when the activity has a parent" do
      it "returns the title of the parent" do
        fund = create(:fund_activity, title: "A parent title")
        programme = create(:programme_activity, parent: fund)
        expect(described_class.new(programme).parent_title).to eql("A parent title")
      end
    end

    context "when the activity does NOT have a parent" do
      it "returns nil" do
        fund = create(:fund_activity, title: "No parent")
        expect(described_class.new(fund).parent_title).to eql(nil)
      end
    end
  end

  describe "#level" do
    context "when the activity is a fund" do
      it "returns the custom_capitalisation version of the string" do
        fund = create(:fund_activity)
        expect(described_class.new(fund).level).to eql("Fund (level A)")
      end
    end

    context "when the activity is a programme" do
      it "returns the custom_capitalisation version of the string" do
        programme = create(:programme_activity)
        expect(described_class.new(programme).level).to eql("Programme (level B)")
      end
    end

    context "when the activity is a project" do
      it "returns the custom_capitalisation version of the string" do
        project = create(:project_activity)
        expect(described_class.new(project).level).to eql("Project (level C)")
      end
    end

    context "when the activity is a third_party_project" do
      it "returns the custom_capitalisation version of the string" do
        third_party_project = create(:third_party_project_activity)
        expect(described_class.new(third_party_project).level).to eql("Third-party project (level D)")
      end
    end
  end

  describe "#tied_status_with_code" do
    it "returns the tied status string & code number" do
      fund = create(:project_activity)
      expect(described_class.new(fund).tied_status_with_code).to eql("Untied (5)")
    end
  end

  describe "#finance_with_code" do
    it "returns the finance string & code number" do
      fund = create(:project_activity)
      expect(described_class.new(fund).finance_with_code).to eql("Standard grant (110)")
    end
  end

  describe "#link_to_roda" do
    it "returns the full URL to the activity in RODA" do
      project = create(:project_activity)
      expect(described_class.new(project).link_to_roda).to eq "http://test.local/organisations/#{project.organisation.id}/activities/#{project.id}/details"
    end
  end

  describe "#actual_total_for_report_financial_quarter" do
    it "returns the transaction total scoped to report as a formatted number" do
      project = create(:project_activity, :with_report)
      report = Report.for_activity(project).first
      current_quarter = FinancialQuarter.for_date(Date.today)
      _transaction_in_report_scope = create(:transaction, parent_activity: project, report: report, value: 100.20, **current_quarter)
      _transaction_outside_report_scope = create(:transaction, parent_activity: project, report: report, value: 300, **current_quarter.pred)

      expect(described_class.new(project).actual_total_for_report_financial_quarter(report: report))
        .to eq "100.20"
    end
  end

  describe "#forecasted_total_for_report_financial_quarter" do
    it "returns the forecast total per report as a formatted number" do
      project = create(:project_activity)
      reporting_cycle = ReportingCycle.new(project, 3, 2020)
      forecast = ForecastHistory.new(project, financial_quarter: 4, financial_year: 2020)

      reporting_cycle.tick
      forecast.set_value(200.20)

      reporting_cycle.tick
      report = Report.for_activity(project).in_historical_order.first

      expect(described_class.new(project).forecasted_total_for_report_financial_quarter(report: report))
        .to eq "200.20"
    end
  end

  describe "#variance_for_report_financial_quarter" do
    it "returns the variance per report as a formatted number" do
      project = create(:project_activity)
      reporting_cycle = ReportingCycle.new(project, 3, 2019)
      forecast = ForecastHistory.new(project, financial_quarter: 4, financial_year: 2019)

      reporting_cycle.tick
      forecast.set_value(1500)

      reporting_cycle.tick
      report = Report.for_activity(project).in_historical_order.first
      _transaction = create(:transaction, parent_activity: project, report: report, value: 200, **report.own_financial_quarter)

      expect(described_class.new(project).variance_for_report_financial_quarter(report: report))
        .to eq "-1300.00"
    end
  end

  describe "#channel_of_delivery_code" do
    it "returns the IATI code and IATI name of item" do
      activity = build(:project_activity, channel_of_delivery_code: "20000")
      result = described_class.new(activity)
      expect(result.channel_of_delivery_code).to eq("20000: Non-Governmental Organisation (NGO) and Civil Society")
    end
  end

  describe "#total_spend" do
    it "returns the value to two decimal places with a currency symbol" do
      activity = build(:programme_activity)
      create(:transaction, parent_activity: activity, value: 20)
      expect(described_class.new(activity).total_spend).to eq("£20.00")
    end
  end

  describe "#total_budget" do
    it "returns the value to two decimal places with a currency symbol" do
      activity = build(:programme_activity)
      create(:budget, parent_activity: activity, value: 50)
      expect(described_class.new(activity).total_budget).to eq("£50.00")
    end
  end

  describe "#total_forecasted" do
    it "returns the value to two decimal places with a currency symbol" do
      activity = build(:programme_activity)

      ReportingCycle.new(activity, 3, 2019).tick
      ForecastHistory.new(activity, financial_quarter: 4, financial_year: 2019).set_value(50)

      expect(described_class.new(activity).total_forecasted).to eq("£50.00")
    end
  end
end
