RSpec.describe Export::Report do
  before(:all) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start

    @report = create(:report)

    @project = create(:project_activity_with_implementing_organisations)

    @implementing_organisation =
      ImplementingOrganisation.create(
        name: "The name of the organisation that implements the activity",
        reference: "IMP-002",
        organisation_type: "10"
      )

    @third_party_project =
      create(
        :third_party_project_activity,
        parent: @project,
        implementing_organisations: [@implementing_organisation]
      )

    @actual_spend =
      create(
        :actual,
        parent_activity_id: @project.id,
        report: @report,
        financial_quarter: @report.financial_quarter,
        financial_year: @report.financial_year
      )

    @forecast =
      ForecastHistory.new(
        @project,
        report: create(:report, financial_quarter: @report.financial_quarter.pred),
        financial_quarter: @report.financial_quarter,
        financial_year: @report.financial_year,
      ).set_value(10_000)

    @comment = create(:comment, commentable: @project, report: @report)

    @headers_for_report = Export::ActivityAttributesOrder.attributes_in_order.map { |att|
      I18n.t("activerecord.attributes.activity.#{att}")
    }
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  context "when there are activities" do
    subject { described_class.new(report: @report) }

    before do
      relation = Activity.where(level: ["project", "third_party_project"])
      finder_double = double(Activity::ProjectsForReportFinder, call: relation)
      allow(Activity::ProjectsForReportFinder).to receive(:new).and_return(finder_double)
    end

    describe "#headers" do
      it "returns the headers" do
        headers = subject.headers

        expect(headers).to include(@headers_for_report.first)
        expect(headers).to include(@headers_for_report.last)
        expect(headers).to include("Implementing organisations")
        expect(headers).to include("Delivery partner organisation")
        expect(headers).to include("Change state")
        expect(headers).to include("Actual net #{@actual_spend.own_financial_quarter}")
        expect(headers).to include("Variance #{@actual_spend.own_financial_quarter}")
        expect(headers).to include("Forecast #{@forecast.own_financial_quarter}")
        expect(headers).to include("Comments in report")
        expect(headers).to include("Link to activity")
      end
    end

    describe "#rows" do
      describe "ordering" do
        it "returns the rows ordered descending by level" do
          relation =
            double(
              ActiveRecord::Relation,
              order: Activity.all,
              pluck: [@project.id, @third_party_project.id]
            )
          finder_double = double(Activity::ProjectsForReportFinder, call: relation)
          allow(Activity::ProjectsForReportFinder).to receive(:new).and_return(finder_double)

          subject.rows

          expect(relation).to have_received(:order).with(level: :asc)
        end
      end

      it "returns the rows correctly" do
        first_row = subject.rows.first.to_a

        expect(roda_identifier_value_for_row(first_row))
          .to eq(@project.roda_identifier)
        expect(implementing_organisation_value_for_row(first_row))
          .to include(@project.implementing_organisations.first.name)
        expect(delivery_partner_organisation_value_for_row(first_row))
          .to eq(@project.organisation.name)
        expect(change_state_value_for_row(first_row))
          .to eq("Unchanged")
        expect(actual_spend_for_row(first_row))
          .to eq(@actual_spend.value)
        expect(variance_for_row(first_row))
          .to eq(@forecast.value - @actual_spend.value)
        expect(forecast_for_row(first_row))
          .to eq(@forecast.value)
        expect(comments_for_row(first_row))
          .to eq(@comment.body)
        expect(link_for_row(first_row))
          .to include(@project.id)
      end
    end

    describe "row caching" do
      it "export rows method if only called once" do
        rows_data_double = double(Hash, fetch: [], empty?: false, any?: true)

        attribute_double = double(rows: rows_data_double)
        allow(Export::ActivityAttributesColumns).to receive(:new).and_return(attribute_double)

        implementing_organisation_double = double(rows: rows_data_double)
        allow(Export::ActivityImplementingOrganisationColumn).to receive(:new).and_return(implementing_organisation_double)

        delivery_partner_organisation_double = double(rows: rows_data_double)
        allow(Export::ActivityDeliveryPartnerOrganisationColumn).to receive(:new).and_return(delivery_partner_organisation_double)

        change_state_double = double(rows: rows_data_double)
        allow(Export::ActivityChangeStateColumn).to receive(:new).and_return(change_state_double)

        actuals_double = double(rows: rows_data_double, headers: rows_data_double, rows_for_last_financial_quarter: double(Hash, fetch: 100))
        allow(Export::ActivityActualsColumns).to receive(:new).and_return(actuals_double)

        variance_double = double(rows: rows_data_double)
        allow(Export::ActivityVarianceColumn).to receive(:new).and_return(variance_double)

        forecasts_double = double(rows: rows_data_double, headers: rows_data_double, rows_for_first_financial_quarter: double(Hash, fetch: 50))
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

        expect(delivery_partner_organisation_double)
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
        expect(headers).to include("Delivery partner organisation")
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
  end

  def roda_identifier_value_for_row(row)
    row[0]
  end

  def implementing_organisation_value_for_row(row)
    row[@headers_for_report.length]
  end

  def delivery_partner_organisation_value_for_row(row)
    row[@headers_for_report.length + 1]
  end

  def change_state_value_for_row(row)
    row[@headers_for_report.length + 2]
  end

  def actual_spend_for_row(row)
    row[@headers_for_report.length + 3]
  end

  def variance_for_row(row)
    row[@headers_for_report.length + 4]
  end

  def forecast_for_row(row)
    row[@headers_for_report.length + 5]
  end

  def comments_for_row(row)
    row[@headers_for_report.length + 6]
  end

  def link_for_row(row)
    row[@headers_for_report.length + 7]
  end
end
