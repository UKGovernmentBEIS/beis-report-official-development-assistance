RSpec.feature "BEIS users can download a report as CSV" do
  let(:beis_user) { create(:beis_user) }

  before do
    Fund.all.each { |fund| create(:fund_activity, source_fund_code: fund.id, roda_identifier: fund.short_name) }
    authenticate! user: beis_user
  end
  after { logout }

  context "when I have a non-ODA report" do
    let(:report) do
      create(
        :report,
        :active,
        :for_ispf,
        description: "Non-ODA report with mixed activities",
        is_oda: false
      )
    end

    context "and it includes actuals from both ODA and non-ODA activities" do
      let(:non_oda_activity) do
        create(
          :project_activity,
          :ispf_funded,
          organisation: report.organisation,
          is_oda: false,
          source_fund_code: Fund.by_short_name("ISPF").id,
          title: "Non-ODA activity"
        )
      end

      let(:oda_activity) do
        create(
          :project_activity,
          :ispf_funded,
          organisation: report.organisation,
          is_oda: true,
          source_fund_code: Fund.by_short_name("ISPF").id,
          title: "ODA activity"
        )
      end

      let(:non_oda_actual) do
        build(
          :actual,
          parent_activity: non_oda_activity,
          description: "Non-ODA actual",
          report: report
        )
      end

      let(:oda_actual) do
        build(
          :actual,
          parent_activity: oda_activity,
          description: "ODA actual",
          report: report
        ).tap do |invalid_actual|
          invalid_actual.save(validate: false)
        end
      end

      before do
        report.actuals << non_oda_actual
        report.actuals << oda_actual
      end

      context "and I view the actuals in the UI" do
        scenario "then I see only non-ODA actuals in UI" do
          visit reports_path

          within "##{report.id}" do
            click_on t("default.link.show")
          end

          within "ul[aria-label='Report subnavigation']" do
            click_on "Actuals / Refunds"
          end

          within "table#actuals" do
            expect(page).to have_content(non_oda_activity.roda_identifier)
            expect(page).to have_no_content(oda_activity.roda_identifier)
          end

          within ".totals" do
            expect(page).to have_content(non_oda_actual.value)
          end
        end
      end

      context "and download the report as a CSV" do
        scenario "then I see only non-ODA actuals in CSV" do
          visit reports_path

          within "##{report.id}" do
            click_on t("default.link.show")
          end

          click_on "Download report as CSV file"

          downloaded_rows = CSV.parse(page.body.delete_prefix("\uFEFF"), headers: true).map(&:to_h)

          expect(downloaded_rows.size).to eq(1)
          expect(downloaded_rows.first.fetch("RODA identifier")).to eq(non_oda_activity.roda_identifier)
        end
      end
    end
  end
end
