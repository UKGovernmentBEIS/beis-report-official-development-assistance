RSpec.describe SpendingBreakdown::Export do
  let!(:organisation) { create(:delivery_partner_organisation, beis_organisation_reference: "BC") }
  let!(:activity) { create(:project_activity, organisation: organisation) }
  let!(:source_fund) { Fund.new(activity.source_fund_code) }
  let!(:actual) { create(:actual, parent_activity: activity, value: 100, financial_quarter: 1, financial_year: 2020) }
  let!(:refund) { create(:refund, parent_activity: activity, value: -200, financial_quarter: 1, financial_year: 2020) }

  let!(:positive_actual_adjustment) { create(:adjustment, :actual, parent_activity: activity, value: 200, financial_quarter: 1, financial_year: 2020) }
  let!(:negative_actual_adjustment) { create(:adjustment, :actual, parent_activity: activity, value: -100, financial_quarter: 1, financial_year: 2020) }

  let!(:positive_refund_adjustment) { create(:adjustment, :refund, parent_activity: activity, value: 50, financial_quarter: 1, financial_year: 2020) }
  let!(:negative_refund_adjustment) { create(:adjustment, :refund, parent_activity: activity, value: -200, financial_quarter: 1, financial_year: 2020) }

  let!(:actual_fq4) { create(:actual, parent_activity: activity, value: 100, financial_quarter: 4, financial_year: 2020) }
  let!(:refund_fq4) { create(:refund, parent_activity: activity, value: -200, financial_quarter: 4, financial_year: 2020) }

  let!(:positive_actual_adjustment_fq4) { create(:adjustment, :actual, parent_activity: activity, value: 200, financial_quarter: 4, financial_year: 2020) }
  let!(:negative_actual_adjustment_fq4) { create(:adjustment, :actual, parent_activity: activity, value: -100, financial_quarter: 4, financial_year: 2020) }

  let!(:positive_refund_adjustment_fq4) { create(:adjustment, :refund, parent_activity: activity, value: 50, financial_quarter: 4, financial_year: 2020) }
  let!(:negative_refund_adjustment_fq4) { create(:adjustment, :refund, parent_activity: activity, value: -200, financial_quarter: 4, financial_year: 2020) }

  subject { SpendingBreakdown::Export.new(organisation: organisation, source_fund: source_fund) }

  def value_for_header(header_name)
    subject.rows.first[subject.headers.index(header_name)]
  end

  describe "#filename" do
    context "when an organisation IS used in construction" do
      it "includes the organisation reference" do
        newton_fund = Fund.new(1)
        breakdown = SpendingBreakdown::Export.new(
          source_fund: newton_fund,
          organisation: organisation
        )
        expect(breakdown.filename).to eq("NF_BC_spending_breakdown.csv")
      end
    end

    context "when NO organisation is used in construction" do
      it "leaves out the organisation reference" do
        newton_fund = Fund.new(1)
        breakdown = SpendingBreakdown::Export.new(source_fund: newton_fund)

        expect(breakdown.filename).to eq("NF_spending_breakdown.csv")
      end
    end
  end

  describe "#headers" do
    it "includes the five headings that describe the activity" do
      expect(subject.headers).to include(
        "RODA identifier",
        "Delivery partner identifier",
        "Delivery partner organisation",
        "Title",
        "Level",
        "Activity status",
      )
    end

    it "includes the three headings that describe the finances for financial quarter 1 2020-2021" do
      expect(subject.headers).to include(
        "Actual spend FQ1 2020-2021",
        "Refund FQ1 2020-2021",
        "Actual net FQ1 2020-2021",
      )
    end

    it "includes the three headings that describe the finances for financial quarter 4 2020-2021" do
      expect(subject.headers).to include(
        "Actual spend FQ4 2020-2021",
        "Refund FQ4 2020-2021",
        "Actual net FQ4 2020-2021",
      )
    end

    it "includes the three headings that describe the finances for financial quarters inbetween" do
      expect(subject.headers).to include(
        "Actual spend FQ2 2020-2021",
        "Refund FQ2 2020-2021",
        "Actual net FQ2 2020-2021",
      )
      expect(subject.headers).to include(
        "Actual spend FQ3 2020-2021",
        "Refund FQ3 2020-2021",
        "Actual net FQ3 2020-2021",
      )
    end
  end

  describe "#rows" do
    describe "non financial data" do
      it "contains the appropriate values" do
        aggregate_failures do
          expect(value_for_header("RODA identifier")).to eql(activity.roda_identifier)
          expect(value_for_header("Delivery partner identifier")).to eql(activity.delivery_partner_identifier)
          expect(value_for_header("Delivery partner organisation")).to eql(activity.organisation.name)
          expect(value_for_header("Title")).to eql(activity.title)
          expect(value_for_header("Level")).to eql("Project (level C)")
          expect(value_for_header("Activity status")).to eql("Spend in progress")
        end
      end
    end

    describe "financial data" do
      it "contains the financial data for financial quarter 1 2020-2021" do
        aggregate_failures do
          expect(value_for_header("Actual spend FQ1 2020-2021").to_s).to eql("200.0")
          expect(value_for_header("Refund FQ1 2020-2021").to_s).to eql("-350.0")
          expect(value_for_header("Actual net FQ1 2020-2021").to_s).to eql("-150.0")
        end
      end

      it "contains the financial data for financial quarter 4 2020-2021" do
        aggregate_failures do
          expect(value_for_header("Actual spend FQ4 2020-2021").to_s).to eql("200.0")
          expect(value_for_header("Refund FQ4 2020-2021").to_s).to eql("-350.0")
          expect(value_for_header("Actual net FQ4 2020-2021").to_s).to eql("-150.0")
        end
      end

      it "contains zero values for the financial quarters inbetween" do
        aggregate_failures do
          expect(value_for_header("Actual spend FQ2 2020-2021").to_s).to eql("0")
          expect(value_for_header("Refund FQ2 2020-2021").to_s).to eql("0")
          expect(value_for_header("Actual net FQ2 2020-2021").to_s).to eql("0")

          expect(value_for_header("Actual spend FQ3 2020-2021").to_s).to eql("0")
          expect(value_for_header("Refund FQ3 2020-2021").to_s).to eql("0")
          expect(value_for_header("Actual net FQ3 2020-2021").to_s).to eql("0")
        end
      end

      context "where there are additional activities" do
        before do
          create_list(:project_activity, 4, organisation: organisation)
        end

        it "includes a row for each" do
          expect(subject.rows.count).to eq(5)
        end
      end
    end
  end
end
