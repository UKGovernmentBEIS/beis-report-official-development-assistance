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
  end
end
