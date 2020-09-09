require "rails_helper"

RSpec.describe ImportTransactions do
  let(:project) { create(:project_activity) }

  let! :report do
    create(:report,
      fund: project.associated_fund,
      organisation: project.organisation,
      state: :active)
  end

  let :importer do
    ImportTransactions.new
  end

  describe "importing a single transaction" do
    let :transaction_row do
      {
        "Activity RODA Identifier" => project.roda_identifier_compound,
        "Date" => "2020-09-08",
        "Value" => "50.00",
        "Receiving Organisation Name" => "Example University",
        "Receiving Organisation Type" => "80",
        "Receiving Organisation IATI Reference" => "",
        "Disbursement Channel" => "",
        "Description" => "Fees for Q3",
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
        description: "Fees for Q3",
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
      )
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

    context "when the Date is not an existing date" do
      let :transaction_row do
        super().merge("Date" => "2020-04-31")
      end

      it "does not import any transactions" do
        expect(report.transactions.count).to eq(0)
      end

      it "returns an error" do
        expect(importer.errors).to eq([
          ImportTransactions::Error.new(0, "Date", "2020-04-31", t("importer.errors.transaction.invalid_date")),
        ])
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
          ImportTransactions::Error.new(0, "Value", "", t("activerecord.errors.models.transaction.attributes.value.other_than")),
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
          ImportTransactions::Error.new(0, "Value", "This is not a number", t("activerecord.errors.models.transaction.attributes.value.other_than")),
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
end
