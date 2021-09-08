RSpec.describe QuarterlyExternalIncomeExport do
  let!(:delivery_partner) { build(:delivery_partner_organisation) }
  let!(:fund) { build(:fund_activity, :newton) }

  let(:project) { build(:project_activity, source_fund: fund, organisation: delivery_partner, id: SecureRandom.uuid) }
  let(:source_fund) { Fund.new(fund.source_fund_code) }
  let(:export) { QuarterlyExternalIncomeExport.new(organisation: delivery_partner, source_fund: source_fund) }

  let(:external_income_relation) { double("ActiveRecord::Relation") }

  # This allows us to have different external incomes in the context below
  let(:external_income) do
    [
      build(:external_income, activity: project, financial_year: 2014, financial_quarter: 1, amount: 10, organisation: delivery_partner),
      build(:external_income, activity: project, financial_year: 2014, financial_quarter: 1, amount: 20, organisation: delivery_partner),
    ]
  end

  # This is where we stub the variables that get returned by `external_incomes` and `activity_ids`
  before do
    allow(Activity).to receive(:where).with(organisation_id: delivery_partner.id, source_fund_code: source_fund.id).and_return([
      project,
    ])

    allow(ExternalIncome).to receive(:includes).with(:activity, :organisation).and_return(external_income_relation)
    allow(external_income_relation).to receive(:where).with(activity_id: [project.id]).and_return(external_income_relation)
    allow(external_income_relation).to receive(:order).with(:activity_id, :financial_year, :financial_quarter).and_return(external_income)
  end

  let :quarter_headers do
    export.headers.drop(7)
  end

  let :external_income_data do
    export.rows.map { |row| row.take(1) + row.drop(7) }
  end

  describe "#filename" do
    it "concatenates the fund short name and the DP org short name" do
      expect(export.filename).to eql("#{source_fund.short_name}_#{delivery_partner.beis_organisation_reference}_external_income.csv")
    end
  end

  it "exports one quarter of external income for a single project" do
    expect(quarter_headers).to eq ["FQ1 2014-2015"]
    expect(export.rows[0]).to eq([
      project.roda_identifier,
      project.delivery_partner_identifier,
      delivery_partner.name,
      project.title,
      "Project (level C)",
      delivery_partner.name,
      "Yes",
      "10.00",
    ])
    expect(external_income_data[1]).to eq([project.roda_identifier, "20.00"])
  end

  context "when there is a single project with intervening quarters" do
    let(:external_income) do
      [
        build(:external_income, activity: project, financial_year: 2014, financial_quarter: 1, amount: 10),
        build(:external_income, activity: project, financial_year: 2014, financial_quarter: 4, amount: 20),
      ]
    end

    it "exports two quarters of external income for the single project" do
      expect(quarter_headers).to eq ["FQ1 2014-2015", "FQ2 2014-2015", "FQ3 2014-2015", "FQ4 2014-2015"]

      expect(external_income_data).to eq([
        [project.roda_identifier, "10.00", "0.00", "0.00", "0.00"],
        [project.roda_identifier, "0.00", "0.00", "0.00", "20.00"],
      ])
    end
  end
end
