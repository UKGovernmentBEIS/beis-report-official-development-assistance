# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActivityPresenter do
  describe "#aid_type" do
    context "when the aid_type exists" do
      it "returns the locale value for the code" do
        activity = build(:activity, aid_type: "a01")
        result = described_class.new(activity).aid_type
        expect(result).to eql("General budget support")
      end

      it "returns the locale value when the code is upper case" do
        activity = build(:activity, aid_type: "A01")
        result = described_class.new(activity).aid_type
        expect(result).to eql("General budget support")
      end
    end

    context "when the activity does not have an aid_type set" do
      it "returns nil" do
        activity = build(:activity, :at_identifier_step)
        result = described_class.new(activity)
        expect(result.aid_type).to be_nil
      end
    end
  end

  describe "#sector" do
    context "when the sector exists" do
      it "returns the locale value for the code" do
        activity = build(:activity, sector: "11110")
        result = described_class.new(activity).sector
        expect(result).to eql("Education policy and administrative management")
      end
    end

    context "when the activity does not have a sector set" do
      it "returns nil" do
        activity = build(:activity, sector: nil)
        result = described_class.new(activity)
        expect(result.sector).to be_nil
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
    context "when the programme status exists" do
      it "returns the locale value for the code" do
        activity = build(:activity, programme_status: "07")
        result = described_class.new(activity).programme_status
        expect(result).to eql("Spend in progress")
      end
    end

    context "when the activity does not have a programme status set" do
      it "returns nil" do
        activity = build(:activity, programme_status: nil)
        result = described_class.new(activity)
        expect(result.programme_status).to be_nil
      end
    end
  end

  describe "#planned_start_date" do
    context "when the planned start date exists" do
      it "returns a human readable date" do
        activity = build(:activity, planned_start_date: "2020-02-25")
        result = described_class.new(activity).planned_start_date
        expect(result).to eql("25 Feb 2020")
      end
    end

    context "when the planned start date does not exist" do
      it "returns nil" do
        activity = build(:activity, planned_start_date: nil)
        result = described_class.new(activity)
        expect(result.planned_start_date).to be_nil
      end
    end
  end

  describe "#planned_end_date" do
    context "when the planned end date exists" do
      it "returns a human readable date" do
        activity = build(:activity, planned_end_date: "2021-04-03")
        result = described_class.new(activity).planned_end_date
        expect(result).to eql("3 Apr 2021")
      end
    end

    context "when the planned end date does not exist" do
      it "returns nil" do
        activity = build(:activity, planned_end_date: nil)
        result = described_class.new(activity)
        expect(result.planned_end_date).to be_nil
      end
    end
  end

  describe "#actual_start_date" do
    context "when the actual start date exists" do
      it "returns a human readable date" do
        activity = build(:activity, actual_start_date: "2020-11-06")
        result = described_class.new(activity).actual_start_date
        expect(result).to eql("6 Nov 2020")
      end
    end

    context "when the actual start date does not exist" do
      it "returns nil" do
        activity = build(:activity, actual_start_date: nil)
        result = described_class.new(activity)
        expect(result.actual_start_date).to be_nil
      end
    end
  end

  describe "#actual_end_date" do
    context "when the actual end date exists" do
      it "returns a human readable date" do
        activity = build(:activity, actual_end_date: "2029-05-27")
        result = described_class.new(activity).actual_end_date
        expect(result).to eql("27 May 2029")
      end
    end

    context "when the actual end date does not exist" do
      it "returns nil" do
        activity = build(:activity, actual_end_date: nil)
        result = described_class.new(activity)
        expect(result.actual_end_date).to be_nil
      end
    end
  end

  describe "#recipient_region" do
    context "when the aid_type recipient_region" do
      it "returns the locale value for the code" do
        activity = build(:activity, recipient_region: "489")
        result = described_class.new(activity).recipient_region
        expect(result).to eql("South America, regional")
      end
    end

    context "when the activity does not have a recipient_region set" do
      it "returns nil" do
        activity = build(:activity, recipient_region: nil)
        result = described_class.new(activity)
        expect(result.recipient_region).to be_nil
      end
    end
  end

  describe "#recipient_country" do
    context "when there is a recipient_country" do
      it "returns the locale value for the code" do
        activity = build(:activity, recipient_country: "CL")
        result = described_class.new(activity).recipient_country
        expect(result).to eq t("activity.recipient_country.#{activity.recipient_country}")
      end
    end

    context "when the activity does not have a recipient_country set" do
      it "returns nil" do
        activity = build(:activity, recipient_country: nil)
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
    context "when there are other benefitting countries" do
      it "returns the locale value for the codes of the countries" do
        activity = build(:activity, intended_beneficiaries: ["AR", "EC", "BR"])
        result = described_class.new(activity).intended_beneficiaries
        expect(result).to eql("Argentina, Ecuador, and Brazil")
      end
    end
  end

  describe "#flow" do
    context "when flow aid_type exists" do
      it "returns the locale value for the code" do
        activity = build(:activity, flow: "20")
        result = described_class.new(activity).flow
        expect(result).to eql("OOF")
      end
    end

    context "when the activity does not have a flow set" do
      it "returns nil" do
        activity = build(:activity, flow: nil)
        result = described_class.new(activity)
        expect(result.flow).to be_nil
      end
    end
  end

  describe "#oda_eligibility" do
    context "when the activity is ODA eligible" do
      it "returns the locale value for this option" do
        activity = build(:project_activity, oda_eligibility: "true")
        result = described_class.new(activity)
        expect(result.oda_eligibility).to eq("Eligible")
      end
    end

    context "when the activity is no longer ODA eligible" do
      it "returns the locale value for this option" do
        activity = build(:project_activity, oda_eligibility: "false")
        result = described_class.new(activity)
        expect(result.oda_eligibility).to eq("No longer eligible")
      end
    end
  end

  describe "#call_to_action" do
    it "returns 'edit' if the desired attribute is present" do
      activity = build(:activity, title: "My title")
      expect(described_class.new(activity).call_to_action(:title)).to eql("edit")
    end

    it "returns 'add' if the desired attribute is not present" do
      activity = build(:activity, title: nil)
      expect(described_class.new(activity).call_to_action(:title)).to eql("add")
    end
  end

  describe "#display_title" do
    context "when the title is nil" do
      it "returns a default display_title" do
        activity = create(:activity, :at_purpose_step, title: nil)
        expect(described_class.new(activity).display_title).to eql("Untitled (#{activity.id})")
      end
    end

    context "when the title is present" do
      it "returns the title" do
        activity = build(:activity)
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
      it "returns the titelized version of the string" do
        fund = create(:fund_activity)
        expect(described_class.new(fund).level).to eql("Fund")
      end
    end

    context "when the activity is a programme" do
      it "returns the titelized version of the string" do
        programme = create(:programme_activity)
        expect(described_class.new(programme).level).to eql("Programme")
      end
    end

    context "when the activity is a project" do
      it "returns the titelized version of the string" do
        project = create(:project_activity)
        expect(described_class.new(project).level).to eql("Project")
      end
    end

    context "when the activity is a third_party_project" do
      it "returns the titelized version of the string" do
        third_party_project = create(:third_party_project_activity)
        expect(described_class.new(third_party_project).level).to eql("Third-party project")
      end
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
      report = Report.find_by(fund: project.associated_fund, organisation: project.organisation)
      _transaction_in_report_scope = create(:transaction, parent_activity: project, report: report, value: 100.20, date: Date.today)
      _transaction_outside_report_scope = create(:transaction, parent_activity: project, report: report, value: 300, date: Date.today - 4.months)

      expect(described_class.new(project).actual_total_for_report_financial_quarter(report: report))
        .to eq "100.20"
    end
  end

  describe "#forecasted_total_for_report_financial_quarter" do
    it "returns the planned disbursement total per report as a formatted number" do
      project = create(:project_activity, :with_report)
      report = Report.find_by(fund: project.associated_fund, organisation: project.organisation)
      _disbursement_1 = create(:planned_disbursement, parent_activity: project, report: report, value: 200.20, period_start_date: Date.today)
      _disbursement_2 = create(:planned_disbursement, parent_activity: project, value: 1500.00)

      expect(described_class.new(project).forecasted_total_for_report_financial_quarter(report: report))
        .to eq "200.20"
    end
  end

  describe "#forecasted_total_for_date_range" do
    it "returns the planned disbursement total for a date range as a formatted number" do
      project = create(:project_activity, :with_report)
      _disbursement_1 = create(:planned_disbursement, parent_activity: project, value: 200.20, period_start_date: Date.today)
      _disbursement_2 = create(:planned_disbursement, parent_activity: project, value: 1500, period_start_date: 3.months.ago)

      expect(described_class.new(project).forecasted_total_for_date_range(range: Date.today.all_quarter))
        .to eq "200.20"
      expect(described_class.new(project).forecasted_total_for_date_range(range: 3.months.ago.all_quarter))
        .to eq "1500.00"
      expect(described_class.new(project).forecasted_total_for_date_range(range: 3.months.from_now.all_quarter))
        .to eq "0.00"
    end
  end

  describe "#variance_for_report_financial_quarter" do
    it "returns the variance per report as a formatted number" do
      project = create(:project_activity, :with_report)
      report = Report.find_by(fund: project.associated_fund, organisation: project.organisation)
      _transaction = create(:transaction, parent_activity: project, report: report, value: 200, date: Date.today)
      _disbursement = create(:planned_disbursement, parent_activity: project, value: 1500, period_start_date: Date.today)

      expect(described_class.new(project).variance_for_report_financial_quarter(report: report))
        .to eq "-1300.00"
    end
  end
end
