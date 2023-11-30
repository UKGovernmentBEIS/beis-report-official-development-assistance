RSpec.describe Export::Report do
  before(:all) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start

    financial_quarter = FinancialQuarter.for_date(Date.parse("31-Mar-2022"))
    financial_year = FinancialYear.for_date(Date.parse("31-Mar-2022"))

    @report = create(
      :report,
      financial_quarter: financial_quarter.to_i,
      financial_year: financial_year.to_i
    )

    @commitment = create(:commitment, value: 50000)
    @project = create(
      :project_activity_with_implementing_organisations,
      implementing_organisations_count: 2,
      commitment: @commitment
    )

    @implementing_organisation =
      create(
        :implementing_organisation,
        name: "The name of the organisation that implements the activity",
        iati_reference: "IMP-002",
        organisation_type: "10"
      )

    @third_party_project =
      create(
        :third_party_project_activity,
        parent: @project
      ).tap do |project|
        project.implementing_organisations << @implementing_organisation
      end

    @actual_spend =
      create(
        :actual,
        parent_activity_id: @project.id,
        report: @report,
        financial_quarter: @report.financial_quarter,
        financial_year: @report.financial_year
      )

    previous_report = create(
      :report,
      financial_quarter: financial_quarter.pred.to_i,
      financial_year: financial_year.to_i
    )

    @forecast =
      ForecastHistory.new(
        @project,
        report: previous_report,
        financial_quarter: @report.financial_quarter,
        financial_year: @report.financial_year
      ).set_value(10_000)

    @comment = create(:comment, commentable: @project, report: @report)

    @headers_for_report = Export::NonIspfActivityAttributesOrder.attributes_in_order.map { |att|
      I18n.t("activerecord.attributes.activity.#{att}")
    }

    @ispf_activity = create(:project_activity, :ispf_funded, tags: [1, 3])

    @ispf_report = create(
      :report,
      financial_quarter: financial_quarter.to_i,
      financial_year: financial_year.to_i,
      fund: @ispf_activity.associated_fund,
      is_oda: @ispf_activity.is_oda
    )
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  context "when there are activities but no forecasts" do
    before do
      financial_quarter = FinancialQuarter.for_date(Date.parse("31-Mar-2022"))
      financial_year = FinancialYear.for_date(Date.parse("31-Mar-2022"))

      @report_without_forecasts = create(
        :report,
        financial_quarter: financial_quarter.to_i,
        financial_year: financial_year.to_i
      )

      @commitment = create(:commitment, value: 120000)

      @project_for_report_without_forecasts = create(
        :project_activity_with_implementing_organisations,
        implementing_organisations_count: 2,
        commitment: @commitment
      )

      @actual_spend_for_report_without_forecasts =
        create(
          :actual,
          parent_activity_id: @project_for_report_without_forecasts.id,
          report: @report_without_forecasts,
          financial_quarter: @report_without_forecasts.financial_quarter,
          financial_year: @report_without_forecasts.financial_year
        )

      relation = Activity.where(id: @project_for_report_without_forecasts.id)
      finder_double = double(Activity::ProjectsForReportFinder, call: relation)
      allow(Activity::ProjectsForReportFinder).to receive(:new).and_return(finder_double)
    end

    subject { described_class.new(report: @report_without_forecasts) }

    it "returns a corresponding number of header columns and row columns" do
      expect(subject.headers.size).to eql(subject.rows.first.to_a.size)
    end

    describe "#headers" do
      it "returns the headers without Variances or Forecasts" do
        headers = subject.headers

        expect(headers).to include(@headers_for_report.first)
        expect(headers).to include(@headers_for_report.last)
        expect(headers).to include("Implementing organisations")
        expect(headers).to include("Partner organisation")
        expect(headers).to include("Change state")
        expect(headers).to include("Original Commitment")
        expect(headers).to include("Actual net #{@actual_spend_for_report_without_forecasts.own_financial_quarter}")
        expect(headers).to include("Total Actuals")
        expect(headers.to_s).to_not include("Variance")
        expect(headers.to_s).to_not include("Forecast")
        expect(headers).to include("Comments in report")
        expect(headers).to include("Link to activity")
        expect(headers).to include("Published on IATI")
      end
    end

    describe "#rows" do
      it "returns the rows correctly" do
        row = subject.rows.first.to_a

        expect(value_for_column("RODA identifier", row))
          .to eql @project_for_report_without_forecasts.roda_identifier
        expect(value_for_column("Partner organisation", row))
          .to eql @project_for_report_without_forecasts.organisation.name
        expect(value_for_column("Change state", row))
          .to eq("Unchanged")
        expect(value_for_column("Original Commitment", row))
          .to eql(@commitment.value)
        expect(value_for_column("Actual net #{@actual_spend_for_report_without_forecasts.own_financial_quarter}", row))
          .to eql @actual_spend_for_report_without_forecasts.value
        expect(value_for_column("Total Actuals", row))
          .to eql @actual_spend_for_report_without_forecasts.value
        expect(value_for_column("Published on IATI", row))
          .to eql "Yes"
      end
    end
  end

  context "when there are activities and forecasts but no actual spend" do
    before do
      financial_quarter = FinancialQuarter.for_date(Date.parse("31-Mar-2022"))
      financial_year = FinancialYear.for_date(Date.parse("31-Mar-2022"))

      @report_without_actuals = create(
        :report,
        financial_quarter: financial_quarter.to_i,
        financial_year: financial_year.to_i
      )

      @commitment = create(:commitment, value: 150000)

      @project_for_report_without_actuals = create(
        :project_activity_with_implementing_organisations,
        implementing_organisations_count: 2,
        commitment: @commitment
      )

      @forecast =
        ForecastHistory.new(
          @project_for_report_without_actuals,
          report: @report_without_actuals,
          financial_quarter: financial_quarter.succ.to_i,
          financial_year: financial_year.succ.to_i
        ).set_value(10_000)

      @comment = create(:comment, commentable: @project_for_report_without_actuals, report: @report_without_actuals)

      relation = Activity.where(id: @project_for_report_without_actuals.id)
      finder_double = double(Activity::ProjectsForReportFinder, call: relation)
      allow(Activity::ProjectsForReportFinder).to receive(:new).and_return(finder_double)
    end

    subject { described_class.new(report: @report_without_actuals) }

    it "returns a corresponding number of header columns and row columns" do
      expect(subject.headers.size).to eql(subject.rows.first.to_a.size)
    end

    describe "#headers" do
      it "returns the headers without Actuals or Variance" do
        headers = subject.headers

        expect(headers).to include(@headers_for_report.first)
        expect(headers).to include(@headers_for_report.last)
        expect(headers).to include("Implementing organisations")
        expect(headers).to include("Partner organisation")
        expect(headers).to include("Change state")
        expect(headers).to include("Original Commitment")
        expect(headers.to_s).to_not include("Actual net")
        expect(headers.to_s).to_not include("Variance")
        expect(headers).not_to include("Total Actuals")
        expect(headers).to include("Forecast #{@forecast.own_financial_quarter}")
        expect(headers).to include("Forecast #{@report_without_actuals.own_financial_quarter}")
        expect(headers).to include("Comments in report")
        expect(headers).to include("Link to activity")
        expect(headers).to include("Published on IATI")
      end
    end

    describe "#rows" do
      it "returns the rows correctly" do
        row = subject.rows.first.to_a

        expect(value_for_column("RODA identifier", row))
          .to eql @project_for_report_without_actuals.roda_identifier
        expect(value_for_column("Partner organisation", row))
          .to eql @project_for_report_without_actuals.organisation.name
        expect(value_for_column("Change state", row))
          .to eql "Unchanged"
        expect(value_for_column("Original Commitment", row))
          .to eql @commitment.value
        expect(value_for_column("Forecast #{@report_without_actuals.own_financial_quarter}", row))
          .to be_zero
        expect(value_for_column("Forecast #{@forecast.own_financial_quarter}", row))
          .to eql @forecast.value
        expect(value_for_column("Comments in report", row))
          .to eql @comment.body
        expect(value_for_column("Published on IATI", row))
          .to eql "Yes"
      end
    end
  end

  context "when there are activities" do
    subject { described_class.new(report: @report) }

    let(:relation) {
      Activity.where(
        level: ["project", "third_party_project"], source_fund_code: @report.fund.source_fund_code
      )
    }

    before do
      finder_double = double(Activity::ProjectsForReportFinder, call: relation)
      allow(Activity::ProjectsForReportFinder).to receive(:new).and_return(finder_double)
    end

    describe "#headers" do
      it "returns the headers" do
        headers = subject.headers

        expect(headers).to include(@headers_for_report.first)
        expect(headers).to include(@headers_for_report.last)
        expect(headers).to include("Implementing organisations")
        expect(headers).to include("Partner organisation")
        expect(headers).to include("Change state")
        expect(headers).to include("Original Commitment")
        expect(headers).to include("Actual net #{@actual_spend.own_financial_quarter}")
        expect(headers).to include("Total Actuals")
        expect(headers).to include("Variance #{@actual_spend.own_financial_quarter}")
        expect(headers).to include("Forecast #{@forecast.own_financial_quarter}")
        expect(headers).to include("Comments in report")
        expect(headers).not_to include("Tags")
        expect(headers).to include("Link to activity")
        expect(headers).to include("Published on IATI")
      end

      context "when the report is for ISPF" do
        subject { described_class.new(report: @ispf_report) }

        it "includes a tags column" do
          expect(subject.headers).to include("Tags")
        end
      end
    end

    describe "#rows" do
      describe "ordering" do
        let(:relation) {
          double(
            ActiveRecord::Relation,
            order: Activity.all,
            pluck: [@project.id, @third_party_project.id]
          )
        }
        it "returns the rows ordered descending by level" do
          subject.rows

          expect(relation).to have_received(:order).with(level: :asc)
        end
      end

      it "returns the rows correctly" do
        row = subject.rows.first.to_a

        expect(value_for_column("RODA identifier", row))
          .to eql @project.roda_identifier
        expect(value_for_column("Implementing organisations", row))
          .to include @project.implementing_organisations.first.name
        expect(value_for_column("Implementing organisations", row))
          .to include @project.implementing_organisations.second.name
        expect(value_for_column("Partner organisation", row))
          .to eql @project.organisation.name
        expect(value_for_column("Change state", row))
          .to eql "Unchanged"
        expect(value_for_column("Original Commitment", row))
          .to eql @commitment.value
        expect(value_for_column("Actual net #{@actual_spend.own_financial_quarter}", row))
          .to eql @actual_spend.value
        expect(value_for_column("Total Actuals", row))
          .to eql @actual_spend.value
        expect(value_for_column("Variance #{@actual_spend.own_financial_quarter}", row))
          .to eql @forecast.value - @actual_spend.value
        expect(value_for_column("Forecast #{@forecast.own_financial_quarter}", row))
          .to eql @forecast.value
        expect(value_for_column("Comments in report", row))
          .to eql @comment.body
        expect(value_for_column("Link to activity", row))
          .to include(@project.id)
        expect(value_for_column("Published on IATI", row))
          .to eql "Yes"
      end

      context "when the report is for ISPF" do
        let(:relation) {
          Activity.where(
            level: ["project", "third_party_project"], source_fund_code: @ispf_report.fund.source_fund_code
          )
        }

        subject { described_class.new(report: @ispf_report) }

        it "returns the rows with the correct tags" do
          first_row = subject.rows.first.to_a
          tags = value_for_column("Tags", first_row)

          expect(tags).to eq("Ayrton Fund|Double-badged for ICF")
        end
      end
    end

    describe "row caching" do
      let(:rows_data_double) { double(Hash, fetch: [], empty?: false, any?: true) }

      it "calls the export rows method only once" do
        attribute_double = double(rows: rows_data_double)
        allow(Export::ActivityAttributesColumns).to receive(:new).and_return(attribute_double)

        implementing_organisation_double = double(rows: rows_data_double)
        allow(Export::ActivityImplementingOrganisationColumn).to receive(:new).and_return(implementing_organisation_double)

        partner_organisation_double = double(rows: rows_data_double)
        allow(Export::ActivityPartnerOrganisationColumn).to receive(:new).and_return(partner_organisation_double)

        change_state_double = double(rows: rows_data_double)
        allow(Export::ActivityChangeStateColumn).to receive(:new).and_return(change_state_double)

        actuals_double = double(rows: rows_data_double, headers: rows_data_double, rows_for_last_financial_quarter: double(Hash, fetch: 100))
        allow(Export::ActivityActualsColumns).to receive(:new).and_return(actuals_double)

        forecasts_rows_data_double = double(Hash, fetch: [], empty?: false, any?: true, values: [{"id" => [100]}])

        variance_double = double(rows: forecasts_rows_data_double)
        allow(Export::ActivityVarianceColumn).to receive(:new).and_return(variance_double)

        forecasts_double = double(rows: forecasts_rows_data_double, headers: rows_data_double, rows_for_first_financial_quarter: double(Hash, fetch: 50))
        allow(Export::ActivityForecastColumns).to receive(:new).and_return(forecasts_double)

        comments_double = double(rows: rows_data_double)
        allow(Export::ActivityCommentsColumn).to receive(:new).and_return(comments_double)

        links_double = double(rows: rows_data_double)
        allow(Export::ActivityLinkColumn).to receive(:new).and_return(links_double)

        subject.rows

        expect(change_state_double)
          .to have_received(:rows)
          .once

        expect(implementing_organisation_double)
          .to have_received(:rows)
          .once

        expect(partner_organisation_double)
          .to have_received(:rows)
          .once

        expect(change_state_double)
          .to have_received(:rows)
          .once

        expect(actuals_double)
          .to have_received(:rows)
          .once

        expect(variance_double)
          .to have_received(:rows)
          .once

        expect(forecasts_double)
          .to have_received(:rows)
          .once

        expect(comments_double)
          .to have_received(:rows)
          .once

        expect(links_double)
          .to have_received(:rows)
          .once
      end

      context "when the report is for ISPF" do
        subject { described_class.new(report: @ispf_report) }

        it "calls the export rows method only once" do
          tags_double = double(rows: rows_data_double)
          allow(Export::ActivityTagsColumn).to receive(:new).and_return(tags_double)

          subject.rows

          expect(tags_double)
            .to have_received(:rows)
            .once
        end
      end
    end
  end

  context "when there are no activities" do
    subject { described_class.new(report: @report) }

    before do
      relation = Activity.none
      finder_double = double(Activity::ProjectsForReportFinder, call: relation)
      allow(Activity::ProjectsForReportFinder).to receive(:new).and_return(finder_double)
    end

    describe "#headers" do
      it "returns the headers" do
        headers = subject.headers

        expect(headers).to include(@headers_for_report.first)
        expect(headers).to include(@headers_for_report.last)
        expect(headers).to include("Implementing organisations")
        expect(headers).to include("Partner organisation")
        expect(headers).to include("Change state")
      end
    end

    describe "#rows" do
      it "returns no rows" do
        expect(subject.rows.count).to eq 0
      end
    end
  end

  describe "#filename" do
    subject { described_class.new(report: @report) }

    it "creates the file name" do
      expect(subject.filename).to include(@report.own_financial_quarter.to_s)
      expect(subject.filename).to include(@report.fund.source_fund.short_name)
      expect(subject.filename).to include(@report.organisation.beis_organisation_reference)
      expect(subject.filename).to include("report.csv")
    end

    context "for an ISPF report" do
      subject { described_class.new(report: build(:report, :for_ispf, is_oda: false)) }

      it "includes the ODA/non-ODA type in the file name" do
        expect(subject.filename).to include("ISPF_Non-ODA")
      end
    end
  end

  describe "@activity_attributes" do
    before do
      allow(Export::ActivityAttributesColumns).to receive(:new).and_call_original
    end

    context "when the report is not for ISPF" do
      let(:report) { build(:report, :for_gcrf) }

      it "includes the non-ISPF activity attributes" do
        described_class.new(report: report)

        expect(Export::ActivityAttributesColumns).to have_received(:new)
          .with(activities: anything, attributes: Export::NonIspfActivityAttributesOrder.attributes_in_order)
      end
    end

    context "when the report is for ISPF" do
      let(:report) { build(:report, :for_ispf) }

      it "includes the ISPF activity attributes" do
        described_class.new(report: report)

        expect(Export::ActivityAttributesColumns).to have_received(:new)
          .with(activities: anything, attributes: Export::IspfActivityAttributesOrder.attributes_in_order)
      end
    end
  end

  def value_for_column(column_header, row)
    index = subject.headers.index(column_header)
    raise "Could not locate the column #{column_header}, check your expectation" if index.nil?

    row[subject.headers.index(column_header)]
  end
end
