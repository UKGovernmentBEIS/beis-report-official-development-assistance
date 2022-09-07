require "rails_helper"

RSpec.describe ImportActuals do
  let(:project) { create(:project_activity, title: "Example Project", description: "Longer description") }

  let(:reporter_organisation) { project.organisation }
  let(:reporter) { create(:partner_organisation_user, organisation: reporter_organisation) }

  let! :report do
    create(:report,
      :active,
      fund: project.associated_fund,
      organisation: project.organisation,
      financial_year: 1999,
      financial_quarter: 4)
  end

  let :importer do
    ImportActuals.new(report: report, uploader: reporter)
  end

  describe "importing a single refund" do
    let :actual_row do
      {
        "Activity RODA Identifier" => project.roda_identifier,
        "Financial Quarter" => "4",
        "Financial Year" => "2019",
        "Actual Value" => nil,
        "Refund Value" => "12.00",
        "Receiving Organisation Name" => "Example University",
        "Receiving Organisation Type" => "80",
        "Receiving Organisation IATI Reference" => "",
        "Comment" => "This is a Refund"
      }
    end

    before do
      importer.import([actual_row])
    end

    it "imports a single refund" do
      expect(report.refunds.count).to eq(1)
      expect(report.refunds.first.comment.body).to eq("This is a Refund")
    end
  end

  describe "importing a single actual" do
    let :actual_row do
      {
        "Activity RODA Identifier" => project.roda_identifier,
        "Financial Quarter" => "4",
        "Financial Year" => "2019",
        "Actual Value" => "50.00",
        "Receiving Organisation Name" => "Example University",
        "Receiving Organisation Type" => "80",
        "Receiving Organisation IATI Reference" => "",
        "Comment" => "Puppy"
      }
    end

    before do
      importer.import([actual_row])
    end

    it "imports a single actual" do
      expect(report.actuals.count).to eq(1)
      expect(report.actuals.first.comment.body).to eq("Puppy")
    end

    it "assigns the attributes from the row data" do
      actual = report.actuals.first

      expect(actual).to have_attributes(
        parent_activity: project,
        financial_quarter: 4,
        financial_year: 2019,
        value: 50.0,
        receiving_organisation_name: "Example University",
        receiving_organisation_type: "80",
        description: "FQ4 1999-2000 spend on Example Project"
      )
    end

    it "assigns a default currency" do
      actual = report.actuals.first
      expect(actual.currency).to eq("GBP")
    end

    # https://iatistandard.org/en/iati-standard/203/codelists/transactiontype/
    it "assigns 'disbursement' as the actual type" do
      actual = report.actuals.first
      expect(actual.transaction_type).to eq("3")
    end

    it "assigns the providing organisation based on the activity" do
      actual = report.actuals.first

      expect(actual).to have_attributes(
        providing_organisation_name: project.providing_organisation.name,
        providing_organisation_type: project.providing_organisation.organisation_type,
        providing_organisation_reference: project.providing_organisation.iati_reference
      )
    end

    context "when the reporter is not authorised to report on the Activity" do
      let(:reporter_organisation) { create(:partner_organisation) }

      it "does not import any actuals" do
        expect(report.actuals.count).to eq(0)
      end

      it "returns an error" do
        expect(importer.errors).to eq([
          ImportActuals::Error.new(0, "Activity RODA Identifier", project.roda_identifier, t("importer.errors.actual.unauthorised"))
        ])
      end
    end

    context "when the Activity does not belong to the given Report" do
      let(:another_project) { create(:project_activity, organisation: reporter_organisation) }

      let :actual_row do
        super().merge("Activity RODA Identifier" => another_project.roda_identifier)
      end

      it "does not import any actuals" do
        expect(report.actuals.count).to eq(0)
      end

      it "returns an error" do
        expect(importer.errors).to eq([
          ImportActuals::Error.new(0, "Activity RODA Identifier", another_project.roda_identifier, t("importer.errors.actual.unauthorised"))
        ])
      end
    end

    context "when the Activity Identifier is not recognised" do
      let :actual_row do
        super().merge("Activity RODA Identifier" => "not-a-real-id")
      end

      it "does not import any actuals" do
        expect(report.actuals.count).to eq(0)
      end

      it "returns an error" do
        expect(importer.errors).to eq([
          ImportActuals::Error.new(0, "Activity RODA Identifier", "not-a-real-id", t("importer.errors.actual.unknown_identifier"))
        ])
      end
    end

    context "when the Financial Quarter is blank" do
      let :actual_row do
        super().merge("Financial Quarter" => "")
      end

      it "does not import any actuals" do
        expect(report.actuals.count).to eq(0)
      end

      it "returns an error" do
        expect(importer.errors).to eq([
          ImportActuals::Error.new(0, "Financial Quarter", "", t("activerecord.errors.models.actual.attributes.financial_quarter.inclusion"))
        ])
      end
    end

    context "when the Financial Year is blank" do
      let :actual_row do
        super().merge("Financial Year" => "")
      end

      it "does not import any actuals" do
        expect(report.actuals.count).to eq(0)
      end

      it "returns an error" do
        expect(importer.errors).to eq([
          ImportActuals::Error.new(0, "Financial Year", "", t("activerecord.errors.models.actual.attributes.financial_year.blank"))
        ])
      end
    end

    context "when the Financial Quarter is invalid" do
      let :actual_row do
        super().merge("Financial Quarter" => "5")
      end

      it "does not import any actuals" do
        expect(report.actuals.count).to eq(0)
      end

      it "returns an error" do
        expect(importer.errors).to eq([
          ImportActuals::Error.new(0, "Financial Quarter", "5", t("activerecord.errors.models.actual.attributes.financial_quarter.inclusion"))
        ])
      end
    end

    context "with additional formatting in the Value field" do
      let :actual_row do
        super().merge("Actual Value" => "£ 12,345.67")
      end

      it "imports the actual" do
        expect(report.actuals.count).to eq(1)
      end

      it "interprets the Value as a number" do
        actual = report.actuals.first
        expect(actual.value).to eq(12_345.67)
      end
    end

    # Note: the higher-level behaviour is that CSV rows with a blank value
    # are skipped entirely. But here it's an error for there to be no data.
    context "when the Actual Value and the Refund Value are blank" do
      let :actual_row do
        super().merge(
          "Actual Value" => "",
          "Refund Value" => ""
        )
      end

      it "does not import any actuals" do
        expect(report.actuals.count).to eq(0)
      end

      it "returns an error" do
        expect(importer.errors).to eq([
          ImportActuals::Error.new(0, "Actual Value", "", t("importer.errors.actual.non_numeric_value")),
          ImportActuals::Error.new(0, "Refund Value", "", t("importer.errors.actual.non_numeric_value"))
        ])
      end
    end

    context "when the Value is zero" do
      let :actual_row do
        super().merge("Actual Value" => "0")
      end

      it "does not import any actuals" do
        expect(report.actuals.count).to eq(0)
      end

      it "does not return an error" do
        expect(importer.errors).to eq([])
      end
    end

    context "when the Value is not numeric" do
      let :actual_row do
        super().merge("Actual Value" => "This is not a number")
      end

      it "does not import any actuals" do
        expect(report.actuals.count).to eq(0)
      end

      it "returns an error" do
        expect(importer.errors).to eq([
          ImportActuals::Error.new(0, "Actual Value", "This is not a number", t("importer.errors.actual.non_numeric_value"))
        ])
      end
    end

    context "when the Value is partially numeric" do
      let :actual_row do
        super().merge("Actual Value" => "3a4b5.c67")
      end

      it "does not import any actuals" do
        expect(report.actuals.count).to eq(0)
      end

      it "returns an error" do
        expect(importer.errors).to eq([
          ImportActuals::Error.new(0, "Actual Value", "3a4b5.c67", t("importer.errors.actual.non_numeric_value"))
        ])
      end
    end

    context "when the Receiving Organisation Name is blank" do
      let :actual_row do
        super().merge("Receiving Organisation Name" => "")
      end

      it "does not import any actuals" do
        expect(report.actuals.count).to eq(0)
      end

      it "returns an error" do
        expect(importer.errors).to eq([
          ImportActuals::Error.new(0, "Receiving Organisation Name", "", t("activerecord.errors.models.actual.attributes.receiving_organisation_name.blank"))
        ])
      end
    end

    # https://iatistandard.org/en/iati-standard/203/codelists/organisationtype/
    context "when the Receiving Organisation Type is not a valid IATI type" do
      let :actual_row do
        super().merge("Receiving Organisation Type" => "81")
      end

      it "does not import any actuals" do
        expect(report.actuals.count).to eq(0)
      end

      it "returns an error" do
        expect(importer.errors).to eq([
          ImportActuals::Error.new(0, "Receiving Organisation Type", "81", t("importer.errors.actual.invalid_iati_organisation_type"))
        ])
      end
    end

    context "when a Receiving Organisation IATI Reference is provided" do
      let :actual_row do
        super().merge("Receiving Organisation IATI Reference" => "Rec-Org-IATI-Ref")
      end

      it "imports the actual" do
        expect(report.actuals.count).to eq(1)
      end

      it "saves the IATI reference on the actual" do
        actual = report.actuals.first
        expect(actual.receiving_organisation_reference).to eq("Rec-Org-IATI-Ref")
      end
    end

    context "when the Receiving Organisation fields are blank" do
      let :actual_row do
        super().merge(
          "Receiving Organisation Name" => "",
          "Receiving Organisation Type" => "",
          "Receiving Organisation IATI Reference" => ""
        )
      end

      it "imports a single actual" do
        expect(report.actuals.count).to eq(1)
      end

      it "assigns the attributes from the row data" do
        actual = report.actuals.first

        expect(actual).to have_attributes(
          parent_activity: project,
          financial_quarter: 4,
          financial_year: 2019,
          value: 50.0,
          receiving_organisation_name: nil,
          receiving_organisation_type: nil,
          description: "FQ4 1999-2000 spend on Example Project"
        )
      end
    end
  end

  describe "importing multiple actuals" do
    let :sibling_project do
      create(:project_activity, organisation: project.organisation, parent: project.parent, title: "Sibling Project")
    end

    let :first_actual_row do
      {
        "Activity RODA Identifier" => sibling_project.roda_identifier,
        "Financial Quarter" => "3",
        "Financial Year" => "2020",
        "Actual Value" => "50.00",
        "Receiving Organisation Name" => "Example University",
        "Receiving Organisation Type" => "80",
        "Comment" => "A comment!"
      }
    end

    let :second_actual_row do
      {
        "Activity RODA Identifier" => project.roda_identifier,
        "Financial Quarter" => "3",
        "Financial Year" => "2020",
        "Actual Value" => "150.00",
        "Receiving Organisation Name" => "Example Corporation",
        "Receiving Organisation Type" => "70",
        "Comment" => ""
      }
    end

    let :third_actual_row do
      {
        "Activity RODA Identifier" => sibling_project.roda_identifier,
        "Financial Quarter" => "3",
        "Financial Year" => "2019",
        "Actual Value" => "£5,000",
        "Receiving Organisation Name" => "Example Foundation",
        "Receiving Organisation Type" => "60",
        "Comment" => "Not blank"
      }
    end

    before do
      importer.import([
        first_actual_row,
        second_actual_row,
        third_actual_row
      ])
    end

    it "imports all actuals successfully" do
      expect(importer.errors).to eq([])
      expect(importer.imported_actuals.count).to eq(3)
      expect(importer.imported_actuals).to match_array(report.actuals)
      expect(report.actuals.first.comment.body).to eq("A comment!")
      expect(report.actuals.second.comment).to be_nil
    end

    it "assigns each actual to the correct report" do
      expect(report.actuals.pluck(:description)).to contain_exactly(
        "FQ4 1999-2000 spend on Example Project",
        "FQ4 1999-2000 spend on Sibling Project",
        "FQ4 1999-2000 spend on Sibling Project"
      )
    end

    it "assigns each actual to the correct activity" do
      expect(project.actuals.pluck(:description)).to eq([
        "FQ4 1999-2000 spend on Example Project"
      ])
      expect(sibling_project.actuals.pluck(:description)).to eq([
        "FQ4 1999-2000 spend on Sibling Project",
        "FQ4 1999-2000 spend on Sibling Project"
      ])
    end

    context "when any row is not valid" do
      let :third_actual_row do
        super().merge("Actual Value" => "fish")
      end

      it "does not import any actuals" do
        expect(Actual.count).to eq(0)
        expect(importer.imported_actuals).to eq([])
      end

      it "returns an error" do
        expect(importer.errors).to eq([
          ImportActuals::Error.new(2, "Actual Value", "fish", t("importer.errors.actual.non_numeric_value"))
        ])
      end
    end

    context "when there are multiple errors" do
      let :first_actual_row do
        super().merge("Receiving Organisation Type" => "81", "Actual Value" => "fish")
      end

      let :third_actual_row do
        super().merge("Financial Quarter" => "5")
      end

      it "does not import any actuals" do
        expect(Actual.count).to eq(0)
      end

      it "returns all the errors" do
        errors = importer.errors.sort_by { |error| [error.row, error.column] }

        expect(errors.size).to eq(3)
        expect(errors).to eq([
          ImportActuals::Error.new(0, "Actual Value", "fish", t("importer.errors.actual.non_numeric_value")),
          ImportActuals::Error.new(0, "Receiving Organisation Type", "81", t("importer.errors.actual.invalid_iati_organisation_type")),
          ImportActuals::Error.new(2, "Financial Quarter", third_actual_row["Financial Quarter"], t("activerecord.errors.models.actual.attributes.financial_quarter.inclusion"))
        ])
      end
    end
  end
end
