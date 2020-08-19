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
        expect(result).to eq I18n.t("activity.recipient_country.#{activity.recipient_country}")
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

  describe "#transactions_total" do
    it "returns the transaction total as a formatted number" do
      project = create(:project_activity)
      _transaction_1 = create(:transaction, parent_activity: project, value: 100.20)
      _transaction_2 = create(:transaction, parent_activity: project, value: 300)

      expect(described_class.new(project).transactions_total)
        .to eq "400.20"
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
end
