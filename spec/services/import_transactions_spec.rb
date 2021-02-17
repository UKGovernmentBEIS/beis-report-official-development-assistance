require "rails_helper"

RSpec.describe ImportTransactions do
  let(:project) { create(:project_activity, title: "Example Project", description: "Longer description") }

  let(:reporter_organisation) { project.organisation }
  let(:reporter) { create(:delivery_partner_user, organisation: reporter_organisation) }

  let! :report do
    create(:report,
      fund: project.associated_fund,
      organisation: project.organisation,
      state: :active,
      financial_year: 1999,
      financial_quarter: 4)
  end

  let :importer do
    ImportTransactions.new(report: report, uploader: reporter)
  end

  describe "importing a single transaction" do
    let :transaction_row do
      {
        "Activity RODA Identifier" => project.roda_identifier,
        "Date" => "8/9/2020",
        "Value" => "50.00",
        "Receiving Organisation Name" => "Example University",
        "Receiving Organisation Type" => "80",
        "Receiving Organisation IATI Reference" => "",
      }
    end

    before do
      importer.import([transaction_row])
    end

    it "imports a single transaction" do
      expect(report.transactions.count).to eq(1)
    end

    it "assigns the attributes from the row data" do
      transaction = report.transactions.first

      expect(transaction).to have_attributes(
        parent_activity: project,
        date: Date.new(2020, 9, 8),
        value: 50.0,
        receiving_organisation_name: "Example University",
        receiving_organisation_type: "80",
        description: "Q4 1999-2000 spend on Example Project",
      )
    end

    it "assigns a default currency" do
      transaction = report.transactions.first
      expect(transaction.currency).to eq("GBP")
    end

    # https://iatistandard.org/en/iati-standard/203/codelists/transactiontype/
    it "assigns 'disbursement' as the transaction type" do
      transaction = report.transactions.first
      expect(transaction.transaction_type).to eq("3")
    end

    it "assigns the providing organisation based on the activity" do
      transaction = report.transactions.first

      expect(transaction).to have_attributes(
        providing_organisation_name: project.providing_organisation.name,
        providing_organisation_type: project.providing_organisation.organisation_type,
        providing_organisation_reference: project.providing_organisation.iati_reference,
      )
    end

    context "when the reporter is not authorised to report on the Activity" do
      let(:reporter_organisation) { create(:organisation) }

      it "does not import any transactions" do
        expect(report.transactions.count).to eq(0)
      end

      it "returns an error" do
        expect(importer.errors).to eq([
          ImportTransactions::Error.new(0, "Activity RODA Identifier", project.roda_identifier, t("importer.errors.transaction.unauthorised")),
        ])
      end
    end

    context "when the Activity does not belong to the given Report" do
      let(:another_project) { create(:project_activity, organisation: reporter_organisation) }

      let :transaction_row do
        super().merge("Activity RODA Identifier" => another_project.roda_identifier)
      end

      it "does not import any transactions" do
        expect(report.transactions.count).to eq(0)
      end

      it "returns an error" do
        expect(importer.errors).to eq([
          ImportTransactions::Error.new(0, "Activity RODA Identifier", another_project.roda_identifier, t("importer.errors.transaction.unauthorised")),
        ])
      end
    end

    context "when the Activity Identifier is not recognised" do
      let :transaction_row do
        super().merge("Activity RODA Identifier" => "not-a-real-id")
      end

      it "does not import any transactions" do
        expect(report.transactions.count).to eq(0)
      end

      it "returns an error" do
        expect(importer.errors).to eq([
          ImportTransactions::Error.new(0, "Activity RODA Identifier", "not-a-real-id", t("importer.errors.transaction.unknown_identifier")),
        ])
      end
    end

    context "when the Date is blank" do
      let :transaction_row do
        super().merge("Date" => "")
      end

      it "does not import any transactions" do
        expect(report.transactions.count).to eq(0)
      end

      it "returns an error" do
        expect(importer.errors).to eq([
          ImportTransactions::Error.new(0, "Date", "", t("activerecord.errors.models.transaction.attributes.date.blank")),
        ])
      end
    end

    context "when the Date is invalid" do
      let :transaction_row do
        super().merge("Date" => "99/4/2020")
      end

      it "does not import any transactions" do
        expect(report.transactions.count).to eq(0)
      end

      it "returns an error" do
        expect(importer.errors).to eq([
          ImportTransactions::Error.new(0, "Date", "99/4/2020", t("importer.errors.transaction.invalid_date")),
        ])
      end

      context "two-digit date" do
        let :transaction_row do
          super().merge("Date" => "21/10/15")
        end

        it "returns an error" do
          expect(importer.errors).to eq([
            ImportTransactions::Error.new(0, "Date", "21/10/15", t("activerecord.errors.models.transaction.attributes.date.between", min: 10, max: 25)),
          ])
        end
      end
    end

    context "with additional formatting in the Value field" do
      let :transaction_row do
        super().merge("Value" => "£ 12,345.67")
      end

      it "imports the transaction" do
        expect(report.transactions.count).to eq(1)
      end

      it "interprets the Value as a number" do
        transaction = report.transactions.first
        expect(transaction.value).to eq(12_345.67)
      end
    end

    context "when the Value is blank" do
      let :transaction_row do
        super().merge("Value" => "")
      end

      it "does not import any transactions" do
        expect(report.transactions.count).to eq(0)
      end

      it "returns an error" do
        expect(importer.errors).to eq([
          ImportTransactions::Error.new(0, "Value", "", t("importer.errors.transaction.non_numeric_value")),
        ])
      end
    end

    context "when the Value is zero" do
      let :transaction_row do
        super().merge("Value" => "0")
      end

      it "does not import any transactions" do
        expect(report.transactions.count).to eq(0)
      end

      it "returns an error" do
        expect(importer.errors).to eq([
          ImportTransactions::Error.new(0, "Value", "0", t("activerecord.errors.models.transaction.attributes.value.other_than")),
        ])
      end
    end

    context "when the Value is not numeric" do
      let :transaction_row do
        super().merge("Value" => "This is not a number")
      end

      it "does not import any transactions" do
        expect(report.transactions.count).to eq(0)
      end

      it "returns an error" do
        expect(importer.errors).to eq([
          ImportTransactions::Error.new(0, "Value", "This is not a number", t("importer.errors.transaction.non_numeric_value")),
        ])
      end
    end

    context "when the Value is partially numeric" do
      let :transaction_row do
        super().merge("Value" => "3a4b5.c67")
      end

      it "does not import any transactions" do
        expect(report.transactions.count).to eq(0)
      end

      it "returns an error" do
        expect(importer.errors).to eq([
          ImportTransactions::Error.new(0, "Value", "3a4b5.c67", t("importer.errors.transaction.non_numeric_value")),
        ])
      end
    end

    context "when the Receiving Organisation Name is blank" do
      let :transaction_row do
        super().merge("Receiving Organisation Name" => "")
      end

      it "does not import any transactions" do
        expect(report.transactions.count).to eq(0)
      end

      it "returns an error" do
        expect(importer.errors).to eq([
          ImportTransactions::Error.new(0, "Receiving Organisation Name", "", t("activerecord.errors.models.transaction.attributes.receiving_organisation_name.blank")),
        ])
      end
    end

    # https://iatistandard.org/en/iati-standard/203/codelists/organisationtype/
    context "when the Receiving Organisation Type is not a valid IATI type" do
      let :transaction_row do
        super().merge("Receiving Organisation Type" => "81")
      end

      it "does not import any transactions" do
        expect(report.transactions.count).to eq(0)
      end

      it "returns an error" do
        expect(importer.errors).to eq([
          ImportTransactions::Error.new(0, "Receiving Organisation Type", "81", t("importer.errors.transaction.invalid_iati_organisation_type")),
        ])
      end
    end

    context "when a Receiving Organisation IATI Reference is provided" do
      let :transaction_row do
        super().merge("Receiving Organisation IATI Reference" => "Rec-Org-IATI-Ref")
      end

      it "imports the transaction" do
        expect(report.transactions.count).to eq(1)
      end

      it "saves the IATI reference on the transaction" do
        transaction = report.transactions.first
        expect(transaction.receiving_organisation_reference).to eq("Rec-Org-IATI-Ref")
      end
    end
  end

  describe "importing multiple transactions" do
    let :sibling_project do
      create(:project_activity, organisation: project.organisation, parent: project.parent, title: "Sibling Project")
    end

    let :first_transaction_row do
      {
        "Activity RODA Identifier" => sibling_project.roda_identifier,
        "Date" => "8/9/2020",
        "Value" => "50.00",
        "Receiving Organisation Name" => "Example University",
        "Receiving Organisation Type" => "80",
      }
    end

    let :second_transaction_row do
      {
        "Activity RODA Identifier" => project.roda_identifier,
        "Date" => "10/9/2020",
        "Value" => "150.00",
        "Receiving Organisation Name" => "Example Corporation",
        "Receiving Organisation Type" => "70",
      }
    end

    let :third_transaction_row do
      {
        "Activity RODA Identifier" => sibling_project.roda_identifier,
        "Date" => "25/12/2019",
        "Value" => "£5,000",
        "Receiving Organisation Name" => "Example Foundation",
        "Receiving Organisation Type" => "60",
      }
    end

    before do
      importer.import([
        first_transaction_row,
        second_transaction_row,
        third_transaction_row,
      ])
    end

    it "imports all transactions successfully" do
      expect(importer.errors).to eq([])
      expect(Transaction.count).to eq(3)
    end

    it "assigns each transaction to the correct report" do
      expect(report.transactions.pluck(:description)).to contain_exactly(
        "Q4 1999-2000 spend on Example Project",
        "Q4 1999-2000 spend on Sibling Project",
        "Q4 1999-2000 spend on Sibling Project",
      )
    end

    it "assigns each transaction to the correct activity" do
      expect(project.transactions.pluck(:description)).to eq([
        "Q4 1999-2000 spend on Example Project",
      ])
      expect(sibling_project.transactions.pluck(:description)).to eq([
        "Q4 1999-2000 spend on Sibling Project",
        "Q4 1999-2000 spend on Sibling Project",
      ])
    end

    context "when any row is not valid" do
      let :third_transaction_row do
        super().merge("Value" => "0")
      end

      it "does not import any transactions" do
        expect(Transaction.count).to eq(0)
      end

      it "returns an error" do
        expect(importer.errors).to eq([
          ImportTransactions::Error.new(2, "Value", "0", t("activerecord.errors.models.transaction.attributes.value.other_than")),
        ])
      end
    end

    context "when there are multiple errors" do
      let :first_transaction_row do
        super().merge("Receiving Organisation Type" => "81")
      end

      let :third_transaction_row do
        super().merge("Date" => 6.months.from_now.strftime("%-d/%-m/%Y"), "Value" => "0")
      end

      it "does not import any transactions" do
        expect(Transaction.count).to eq(0)
      end

      it "returns all the errors" do
        errors = importer.errors.sort_by { |error| [error.row, error.column] }

        expect(errors).to eq([
          ImportTransactions::Error.new(0, "Receiving Organisation Type", "81", t("importer.errors.transaction.invalid_iati_organisation_type")),
          ImportTransactions::Error.new(2, "Date", third_transaction_row["Date"], t("activerecord.errors.models.transaction.attributes.date.not_in_future")),
          ImportTransactions::Error.new(2, "Value", "0", t("activerecord.errors.models.transaction.attributes.value.other_than")),
        ])
      end
    end
  end
end
