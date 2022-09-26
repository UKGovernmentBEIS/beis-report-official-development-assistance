require "rails_helper"

RSpec.describe Budget::Import do
  let(:uploader) { create(:beis_user) }
  let(:programme_activity) { create(:programme_activity) }

  let(:new_direct_budget_attributes) do
    {
      "Type" => "0",
      "Financial year" => "2011-2012",
      "Budget amount" => "12345",
      "Activity RODA ID" => programme_activity.roda_identifier
    }
  end

  subject { described_class.new(uploader: uploader) }

  context "when creating a new budget" do
    let(:level_b_policy_double) { instance_double("LevelBPolicy", budget_upload?: true) }

    before do
      allow(LevelBPolicy).to receive(:new).with(uploader, nil).and_return(level_b_policy_double)
    end

    context "with a type of direct" do
      it "creates the budget" do
        expect { subject.import([new_direct_budget_attributes]) }.to change { Budget.count }.by(1)

        expect(subject.created.count).to eq(1)

        expect(subject.errors.count).to eq(0)

        new_budget = Budget.order(:created_at).last
        budget_type = "direct"
        financial_year = FinancialYear.new(new_direct_budget_attributes["Financial year"])

        expect(new_budget.budget_type).to eq(budget_type)
        expect(new_budget.financial_year).to eq(financial_year)
        expect(new_budget.value).to eq(new_direct_budget_attributes["Budget amount"].to_f)
        expect(new_budget.parent_activity).to eq(programme_activity)

        expect(new_budget.period_start_date).to eq(financial_year.start_date)
        expect(new_budget.period_end_date).to eq(financial_year.end_date)
        expect(new_budget.currency).to eq("GBP")
        expect(new_budget.ingested).to eq(false)
        expect(new_budget.report_id).to be_nil
        expect(new_budget.funding_type).to be_nil
        expect(new_budget.providing_organisation_id).to eq(beis_organisation_id)
        expect(new_budget.providing_organisation_name).to be_nil
        expect(new_budget.providing_organisation_type).to be_nil
        expect(new_budget.providing_organisation_reference).to be_nil
      end

      it "has errors if the budget type is invalid" do
        new_direct_budget_attributes["Type"] = "99999"

        expect { subject.import([new_direct_budget_attributes]) }.to_not change { Budget.count }

        expect(subject.created.count).to eq(0)

        expect(subject.errors.count).to eq(3)
        expect(subject.errors.first.csv_row).to eq(2)
        expect(subject.errors.first.csv_column).to eq("Type")
        expect(subject.errors.first.column).to eq(:budget_type)
        expect(subject.errors.first.value).to eq("99999")
        expect(subject.errors.first.message).to eq(I18n.t("importer.errors.budget.invalid_budget_type"))

        expect(subject.errors.second.column).to eq(:providing_organisation_name)
        expect(subject.errors.third.column).to eq(:providing_organisation_type)
      end

      context "financial year" do
        [
          {
            statement: "has an error if the start and end years are non-contiguous",
            value: "1999-2013"
          },
          {
            statement: "has an error if only one year is provided",
            value: "2020"
          }
        ].each do |example|
          it example[:statement] do
            new_direct_budget_attributes["Financial year"] = example[:value]

            expect { subject.import([new_direct_budget_attributes]) }.to_not change { Budget.count }

            expect(subject.created.count).to eq(0)

            expect(subject.errors.count).to eq(1)
            expect(subject.errors.first.csv_row).to eq(2)
            expect(subject.errors.first.csv_column).to eq("Financial year")
            expect(subject.errors.first.column).to eq(:financial_year)
            expect(subject.errors.first.value).to eq(example[:value])
            expect(subject.errors.first.message).to eq(I18n.t("importer.errors.budget.invalid_financial_year"))
          end
        end
      end

      context "budget amount" do
        [
          {
            statement: "has an error when missing",
            value: ""
          },
          {
            statement: "has an error when zero",
            value: "0"
          },
          {
            statement: "has an error when too high",
            value: "99999999999.01"
          }
        ].each do |example|
          it example[:statement] do
            new_direct_budget_attributes["Budget amount"] = example[:value]

            expect { subject.import([new_direct_budget_attributes]) }.to_not change { Budget.count }

            expect(subject.created.count).to eq(0)

            expect(subject.errors.count).to eq(1)
            expect(subject.errors.first.csv_row).to eq(2)
            expect(subject.errors.first.csv_column).to eq("Budget amount")
            expect(subject.errors.first.column).to eq(:value)
            expect(subject.errors.first.value).to eq(example[:value])
            expect(subject.errors.first.message).to eq(I18n.t("importer.errors.budget.invalid_value"))
          end
        end
      end

      context "parent activity" do
        it "has an error when missing" do
          new_direct_budget_attributes["Activity RODA ID"] = ""

          expect { subject.import([new_direct_budget_attributes]) }.to_not change { Budget.count }

          expect(subject.created.count).to eq(0)

          expect(subject.errors.count).to eq(1)
          expect(subject.errors.first.csv_row).to eq(2)
          expect(subject.errors.first.csv_column).to eq("Activity RODA ID")
          expect(subject.errors.first.column).to eq(:parent_activity_id)
          expect(subject.errors.first.value).to eq("")
          expect(subject.errors.first.message).to eq(I18n.t("importer.errors.budget.cannot_create"))
        end

        it "has an error when not found" do
          new_direct_budget_attributes["Activity RODA ID"] = "111111"

          expect { subject.import([new_direct_budget_attributes]) }.to_not change { Budget.count }

          expect(subject.created.count).to eq(0)

          expect(subject.errors.count).to eq(1)
          expect(subject.errors.first.csv_row).to eq(2)
          expect(subject.errors.first.csv_column).to eq("Activity RODA ID")
          expect(subject.errors.first.column).to eq(:parent_activity_id)
          expect(subject.errors.first.value).to eq("111111")
          expect(subject.errors.first.message).to eq(I18n.t("importer.errors.budget.parent_not_found"))
        end
      end
    end

    context "with a type of other official" do
      let(:new_other_official_budget_attributes) do
        {
          "Type" => "1",
          "Financial year" => "2016-2017",
          "Budget amount" => "67890",
          "Providing organisation" => "Lovely Co",
          "Providing organisation type" => "24",
          "IATI reference" => "top-tier-transparency",
          "Activity RODA ID" => programme_activity.roda_identifier
        }
      end

      [
        {
          statement: "with an IATI reference",
          value: "top-tier-transparency"
        },
        {
          statement: "without an IATI reference",
          value: ""
        }
      ].each do |example|
        context example[:statement] do
          it "creates the budget" do
            new_other_official_budget_attributes["IATI reference"] = example[:value]

            expect { subject.import([new_other_official_budget_attributes]) }.to change { Budget.count }.by(1)

            expect(subject.created.count).to eq(1)

            expect(subject.errors.count).to eq(0)

            new_budget = Budget.order(:created_at).last
            budget_type = "other_official"
            financial_year = FinancialYear.new(new_other_official_budget_attributes["Financial year"])

            expect(new_budget.budget_type).to eq(budget_type)
            expect(new_budget.financial_year).to eq(financial_year)
            expect(new_budget.value).to eq(new_other_official_budget_attributes["Budget amount"].to_f)
            expect(new_budget.parent_activity).to eq(programme_activity)
            expect(new_budget.providing_organisation_name).to eq(new_other_official_budget_attributes["Providing organisation"])
            expect(new_budget.providing_organisation_type).to eq(new_other_official_budget_attributes["Providing organisation type"])

            if example[:value].present?
              expect(new_budget.providing_organisation_reference).to eq(new_other_official_budget_attributes["IATI reference"])
            else
              expect(new_budget.providing_organisation_reference).to be_nil
            end

            expect(new_budget.period_start_date).to eq(financial_year.start_date)
            expect(new_budget.period_end_date).to eq(financial_year.end_date)
            expect(new_budget.currency).to eq("GBP")
            expect(new_budget.ingested).to eq(false)
            expect(new_budget.report_id).to be_nil
            expect(new_budget.funding_type).to be_nil
            expect(new_budget.providing_organisation_id).to be_nil
          end
        end
      end

      it "has an error if the providing organisation is missing" do
        new_other_official_budget_attributes["Providing organisation"] = ""

        expect { subject.import([new_other_official_budget_attributes]) }.to_not change { Budget.count }

        expect(subject.created.count).to eq(0)

        expect(subject.errors.count).to eq(1)
        expect(subject.errors.first.csv_row).to eq(2)
        expect(subject.errors.first.csv_column).to eq("Providing organisation")
        expect(subject.errors.first.column).to eq(:providing_organisation_name)
        expect(subject.errors.first.value).to eq("")
        expect(subject.errors.first.message).to eq(I18n.t("importer.errors.budget.invalid_providing_organisation_name"))
      end

      it "has an error if the providing organisation type is not valid" do
        new_other_official_budget_attributes["Providing organisation type"] = "99999"

        expect { subject.import([new_other_official_budget_attributes]) }.to_not change { Budget.count }

        expect(subject.created.count).to eq(0)

        expect(subject.errors.count).to eq(1)
        expect(subject.errors.first.csv_row).to eq(2)
        expect(subject.errors.first.csv_column).to eq("Providing organisation type")
        expect(subject.errors.first.column).to eq(:providing_organisation_type)
        expect(subject.errors.first.value).to eq("99999")
        expect(subject.errors.first.message).to eq(I18n.t("importer.errors.budget.invalid_providing_organisation_type"))
      end
    end
  end

  def beis_organisation_id
    Organisation.find_by(name: "Department for Business, Energy and Industrial Strategy").id
  end
end
