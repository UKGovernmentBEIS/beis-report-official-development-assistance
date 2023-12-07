require "rails_helper"

RSpec.describe Import::Transactions::ActualAndRefundCsvRow, type: :model do
  before do
    @providing_organisation = build(:partner_organisation)
    @activity = build(:project_activity, title: "Activity Title", organisation: @providing_organisation)
    allow(@activity).to receive(:providing_organisation).and_return(@providing_organisation)
    allow(Activity).to receive(:find_by_roda_identifier).and_return(@activity)
  end

  describe "#activity" do
    it "returns the activity the csv row represents" do
      csv_row = double(CSV::Row)
      allow(csv_row).to receive(:field).with("Activity RODA Identifier")
      row = described_class.new(csv_row)

      expect(row.activity).to be(@activity)
    end

    context "when the RODA Identifier cannot be found" do
      it "returns nil and adds an error" do
        csv_row = double(CSV::Row)
        allow(csv_row).to receive(:field).with("Activity RODA Identifier")
        allow(Activity).to receive(:find_by_roda_identifier).and_return(nil)
        row = described_class.new(csv_row)

        expect(row.activity).to be_nil
        expect(row.errors["Activity RODA Identifier"][1]).to include("cannot be found")
      end
    end

    context "when called multiple times" do
      it "caches the response from the database" do
        csv_row = double(CSV::Row)
        allow(csv_row).to receive(:field).with("Activity RODA Identifier")
        row = described_class.new(csv_row)

        row.activity
        row.activity
        row.activity

        expect(Activity).to have_received(:find_by_roda_identifier).once
      end
    end
  end

  describe "#roda_identifier" do
    it "returns the identifier string" do
      csv_row = double(CSV::Row)
      allow(csv_row).to receive(:field).with("Activity RODA Identifier").and_return("RODA-ID")
      row = described_class.new(csv_row)

      expect(row.roda_identifier).to eql("RODA-ID")
    end

    context "when the RODA Identifier is blank" do
      it "returns blank" do
        csv_row = double(CSV::Row)
        allow(csv_row).to receive(:field).with("Activity RODA Identifier").and_return(nil)
        row = described_class.new(csv_row)

        expect(row.roda_identifier).to eql(:blank)
      end
    end
  end

  describe "#actual_value" do
    it "returns the value from the csv row coerced to a big integer" do
      csv_row = double(CSV::Row)
      allow(csv_row).to receive(:field).with("Actual Value").and_return("10000.50")
      row = described_class.new(csv_row)

      expect(row.actual_value).to eql BigDecimal("10000.50")
    end

    context "when the value is zero" do
      it "return the value from the csv row coerced to a big integer" do
        csv_row = double(CSV::Row)
        allow(csv_row).to receive(:field).with("Actual Value").and_return("0")
        row = described_class.new(csv_row)

        expect(row.actual_value).to eql BigDecimal("0")
      end
    end

    context "when the value is not a number" do
      it "returns the value from the csv row" do
        csv_row = double(CSV::Row)
        allow(csv_row).to receive(:field).with("Actual Value").and_return("not a number")
        row = described_class.new(csv_row)

        expect(row.actual_value).to eql "not a number"
      end
    end

    context "when there is no value" do
      it "returns blank" do
        csv_row = double(CSV::Row)
        allow(csv_row).to receive(:field).with("Actual Value").and_return(nil)
        row = described_class.new(csv_row)

        expect(row.actual_value).to eql(:blank)
      end
    end
  end

  describe "#refund_value" do
    it "returns the value from the csv row" do
      csv_row = double(CSV::Row)
      allow(csv_row).to receive(:field).with("Refund Value").and_return("12030.95")
      row = described_class.new(csv_row)

      expect(row.refund_value).to eql BigDecimal("12030.95")
    end

    context "when the value is zero" do
      it "return the value from the csv row coerced to a big integer" do
        csv_row = double(CSV::Row)
        allow(csv_row).to receive(:field).with("Refund Value").and_return("0")
        row = described_class.new(csv_row)

        expect(row.refund_value).to eql BigDecimal("0")
      end
    end

    context "when the value is not a number" do
      it "returns the value from the csv row" do
        csv_row = double(CSV::Row)
        allow(csv_row).to receive(:field).with("Refund Value").and_return("not a number")
        row = described_class.new(csv_row)

        expect(row.refund_value).to eql "not a number"
      end
    end

    context "when there is no value" do
      it "returns blank" do
        csv_row = double(CSV::Row)
        allow(csv_row).to receive(:field).with("Refund Value").and_return(nil)
        row = described_class.new(csv_row)

        expect(row.refund_value).to eql(:blank)
      end
    end
  end

  describe "#comment" do
    it "returns the value from the csv row" do
      row = described_class.new(valid_csv_row)

      expect(row.comment).to eql("This is a comment.")
    end

    context "when the comment is empty" do
      it "returns blank" do
        csv_row = double(CSV::Row)
        allow(csv_row).to receive(:field).with("Comment").and_return(nil)
        row = described_class.new(csv_row)

        expect(row.comment).to eql(:blank)
      end
    end
  end

  describe "#providing_organisation" do
    it "returns the activity providing organisation" do
      row = described_class.new(valid_csv_row)

      expect(row.providing_organisation).to be(@providing_organisation)
    end

    context "when there is no activity" do
      it "returns nil" do
        row = described_class.new(valid_csv_row)
        allow(Activity).to receive(:find_by_roda_identifier).and_return(nil)

        expect(row.providing_organisation).to be_nil
      end
    end
  end

  describe "#description" do
    it "returns a description that includes the financial quarter, year and title" do
      row = described_class.new(valid_csv_row)

      expect(row.description).to eql("FQ2023 3-4 spend on Activity Title")
    end

    it "returns nil when the quarter is not valid" do
      csv_row = double(CSV::Row)
      allow(csv_row).to receive(:field).with("Financial Quarter").and_return("7")
      allow(csv_row).to receive(:field).with("Financial Year").and_return("2023")
      row = described_class.new(csv_row)

      expect(row.description).to be_nil
    end

    it "returns nil when the year is not valid" do
      csv_row = double(CSV::Row)
      allow(csv_row).to receive(:field).with("Financial Quarter").and_return("3")
      allow(csv_row).to receive(:field).with("Financial Year").and_return("Twenty twenty three")
      row = described_class.new(csv_row)

      expect(row.description).to be_nil
    end
  end

  describe "#financial_quarter" do
    it "returns the value from the row" do
      csv_row = double(CSV::Row)
      allow(csv_row).to receive(:field).with("Financial Quarter").and_return("3")
      row = described_class.new(csv_row)

      expect(row.financial_quarter).to eql("3")
    end

    context "when the value is not valid" do
      it "returns the value for validation later" do
        csv_row = double(CSV::Row)
        allow(csv_row).to receive(:field).with("Financial Quarter").and_return("fish")
        row = described_class.new(csv_row)

        expect(row.financial_quarter).to eql("fish")
      end
    end
  end

  describe "#financial_year" do
    it "returns the value from the row" do
      csv_row = double(CSV::Row)
      allow(csv_row).to receive(:field).with("Financial Year").and_return("2023")
      row = described_class.new(csv_row)

      expect(row.financial_year).to eql("2023")
    end

    context "when the value is not valid" do
      it "returns the value for validation later" do
        csv_row = double(CSV::Row)
        allow(csv_row).to receive(:field).with("Financial Year").and_return("fish")
        row = described_class.new(csv_row)

        expect(row.financial_year).to eql("fish")
      end
    end
  end

  describe "#receiving_organisation_name" do
    it "returns the value from the csv row" do
      csv_row = double(CSV::Row)
      allow(csv_row).to receive(:field).with("Receiving Organisation Name").and_return("The Receiving Organisation")
      row = described_class.new(csv_row)

      expect(row.receiving_organisation_name).to eql("The Receiving Organisation")
    end

    context "when the receiving organisation name is empty" do
      it "returns blank" do
        csv_row = double(CSV::Row)
        allow(csv_row).to receive(:field).with("Receiving Organisation Name").and_return(nil)
        row = described_class.new(csv_row)

        expect(row.receiving_organisation_name).to eql(:blank)
      end
    end
  end

  describe "#receiving_organisation_itai_reference" do
    it "returns the value from the csv row" do
      csv_row = double(CSV::Row)
      allow(csv_row).to receive(:field).with("Receiving Organisation IATI Reference").and_return("IATI-123456")
      row = described_class.new(csv_row)

      expect(row.receiving_organisation_iati_reference).to eql("IATI-123456")
    end

    context "when the value is empty" do
      it "returns blank" do
        csv_row = double(CSV::Row)
        allow(csv_row).to receive(:field).with("Receiving Organisation IATI Reference").and_return(nil)
        row = described_class.new(csv_row)

        expect(row.receiving_organisation_iati_reference).to eql(:blank)
      end
    end
  end

  describe "#receiving_organisation_type" do
    context "when the type code is from the code list" do
      it "returns the value from the row" do
        csv_row = double(CSV::Row)
        allow(csv_row).to receive(:field).with("Receiving Organisation Type").and_return("10")
        row = described_class.new(csv_row)

        expect(row.receiving_organisation_type).to eql("10")
      end
    end

    context "when the type code is not from the code list" do
      it "returns the value for validation later" do
        csv_row = double(CSV::Row)
        allow(csv_row).to receive(:field).with("Receiving Organisation Type").and_return("10000")
        row = described_class.new(csv_row)

        expect(row.receiving_organisation_type).to eql("10000")
      end
    end

    context "when the receiving organisation type is empty" do
      it "returns blank" do
        csv_row = double(CSV::Row)
        allow(csv_row).to receive(:field).with("Receiving Organisation Type").and_return(nil)
        row = described_class.new(csv_row)

        expect(row.receiving_organisation_type).to eql(:blank)
      end
    end
  end

  describe "#transaction_type" do
    context "when the actual value is not zero and the refund value is zero" do
      it "returns actual" do
        csv_row = double(CSV::Row)
        allow(csv_row).to receive(:field).with("Actual Value").and_return("10000.50")
        allow(csv_row).to receive(:field).with("Refund Value").and_return("0")
        allow(csv_row).to receive(:field).with("Comment").and_return("This is a comment on an actual")
        row = described_class.new(csv_row)

        expect(row.transaction_type).to eql :actual
      end
    end

    context "when the actual value is not a number and the refund value is zero" do
      it "returns nil" do
        csv_row = double(CSV::Row)
        allow(csv_row).to receive(:field).with("Actual Value").and_return("not a number")
        allow(csv_row).to receive(:field).with("Refund Value").and_return("0")
        allow(csv_row).to receive(:field).with("Comment").and_return("This is a comment on an actual")
        row = described_class.new(csv_row)

        expect(row.transaction_type).to be_nil
      end
    end

    context "when the actual value is zero and the refund value is not zero" do
      it "returns refund" do
        csv_row = double(CSV::Row)
        allow(csv_row).to receive(:field).with("Actual Value").and_return("0")
        allow(csv_row).to receive(:field).with("Refund Value").and_return("10000.32")
        allow(csv_row).to receive(:field).with("Comment").and_return("This is a comment on an refund")
        row = described_class.new(csv_row)

        expect(row.transaction_type).to eql :refund
      end
    end

    context "when the refund value is not a number and the actual value is zero" do
      it "returns nil" do
        csv_row = double(CSV::Row)
        allow(csv_row).to receive(:field).with("Actual Value").and_return("0")
        allow(csv_row).to receive(:field).with("Refund Value").and_return("not a number")
        allow(csv_row).to receive(:field).with("Comment").and_return("This is a comment on an actual")
        row = described_class.new(csv_row)

        expect(row.transaction_type).to be_nil
      end
    end

    context "when the actual and refund values are not numbers" do
      it "returns nil" do
        csv_row = double(CSV::Row)
        allow(csv_row).to receive(:field).with("Actual Value").and_return("not a number")
        allow(csv_row).to receive(:field).with("Refund Value").and_return("not a number")
        allow(csv_row).to receive(:field).with("Comment").and_return("This is a comment on an actual")
        row = described_class.new(csv_row)

        expect(row.transaction_type).to be_nil
      end
    end

    context "when the actual value is zero and the refund value is zero" do
      context "and there is a comment" do
        it "returns comment" do
          csv_row = double(CSV::Row)
          allow(csv_row).to receive(:field).with("Actual Value").and_return("0")
          allow(csv_row).to receive(:field).with("Refund Value").and_return("0")
          allow(csv_row).to receive(:field).with("Comment").and_return("This is a comment on no actual or refund")
          row = described_class.new(csv_row)

          expect(row.transaction_type).to eql :comment
        end
      end

      context "and there is not a comment" do
        it "returns nil" do
          csv_row = double(CSV::Row)
          allow(csv_row).to receive(:field).with("Actual Value").and_return("0")
          allow(csv_row).to receive(:field).with("Refund Value").and_return("0")
          allow(csv_row).to receive(:field).with("Comment").and_return(nil)
          row = described_class.new(csv_row)

          expect(row.transaction_type).to be_nil
        end
      end

      context "when the actual value, refund value and comment are blank" do
        it "returns blank" do
          csv_row = double(CSV::Row)
          allow(csv_row).to receive(:field).with("Actual Value").and_return(nil)
          allow(csv_row).to receive(:field).with("Refund Value").and_return(nil)
          allow(csv_row).to receive(:field).with("Comment").and_return(nil)
          row = described_class.new(csv_row)

          expect(row.transaction_type).to eql :blank
        end
      end
    end
  end

  describe "validations" do
    context "when the RODA identifier is blank" do
      it "is invalid with an error" do
        csv_row = valid_csv_row
        allow(csv_row).to receive(:field).and_call_original
        allow(csv_row).to receive(:field).with("Activity RODA Identifier").and_return(nil)
        row = described_class.new(csv_row)

        expect(row).to be_invalid
        expect(row.errors["Activity RODA Identifier"][1]).to eql("Cannot be blank")
      end
    end

    context "when the financial quarter is blank" do
      it "is invalid with an error" do
        csv_row = valid_csv_row
        allow(csv_row).to receive(:field).and_call_original
        allow(csv_row).to receive(:field).with("Financial Quarter").and_return(nil)
        row = described_class.new(csv_row)

        expect(row).to be_invalid
        expect(row.errors["Financial Quarter"][1]).to eql("Cannot be blank")
      end
    end

    context "when the financial quarter is not 1, 2, 3 or 4" do
      it "is invalid with an error" do
        csv_row = valid_csv_row
        allow(csv_row).to receive(:field).and_call_original
        allow(csv_row).to receive(:field).with("Financial Quarter").and_return("5")
        row = described_class.new(csv_row)

        expect(row).to be_invalid
        expect(row.errors["Financial Quarter"][1]).to eql("Must be 1, 2, 3 or 4")
      end
    end

    context "when the financial year is blank" do
      it "is invalid with an error" do
        csv_row = valid_csv_row
        allow(csv_row).to receive(:field).and_call_original
        allow(csv_row).to receive(:field).with("Financial Year").and_return(nil)
        row = described_class.new(csv_row)

        expect(row).to be_invalid
        expect(row.errors["Financial Year"][1]).to eql("Cannot be blank")
      end
    end

    context "when the financial year is not a four digit year"

    describe "actuals" do
      it_behaves_like "a financial value in a csv row", "Actual Value"

      context "when there is also refund value" do
        it "is invalid" do
          csv_row = valid_csv_row
          allow(csv_row).to receive(:field).and_call_original
          allow(csv_row).to receive(:field).with("Actual Value").and_return("1000.00")
          allow(csv_row).to receive(:field).with("Refund Value").and_return("1000.00")
          row = described_class.new(csv_row)

          expect(row).to be_invalid
          expect(row.errors["Actual Value"][1]).to include("cannot report actual and refunds together")
        end

        context "when the refund is zero" do
          it "is valid" do
            csv_row = valid_csv_row
            allow(csv_row).to receive(:field).and_call_original
            allow(csv_row).to receive(:field).with("Actual Value").and_return("1000.00")
            allow(csv_row).to receive(:field).with("Refund Value").and_return("0.00")
            row = described_class.new(csv_row)

            expect(row).to be_valid
          end
        end

        context "when the refund is blank" do
          it "is valid" do
            csv_row = valid_csv_row
            allow(csv_row).to receive(:field).and_call_original
            allow(csv_row).to receive(:field).with("Actual Value").and_return("1000.00")
            allow(csv_row).to receive(:field).with("Refund Value").and_return(nil)
            row = described_class.new(csv_row)

            expect(row).to be_valid
          end
        end
      end
    end

    describe "refunds" do
      it_behaves_like "a financial value in a csv row", "Refund Value"

      context "when there is a comment" do
        it "is valid" do
          csv_row = valid_csv_row
          allow(csv_row).to receive(:field).and_call_original
          allow(csv_row).to receive(:field).with("Refund Value").and_return("1000.00")
          allow(csv_row).to receive(:field).with("Comment").and_return("This is the comment for the refund")
          row = described_class.new(csv_row)

          expect(row).to be_valid
        end
      end

      context "when there is no comment" do
        it "is invalid" do
          csv_row = valid_csv_row
          allow(csv_row).to receive(:field).and_call_original
          allow(csv_row).to receive(:field).with("Refund Value").and_return("1000.00")
          allow(csv_row).to receive(:field).with("Comment").and_return(:blank)
          row = described_class.new(csv_row)

          expect(row).to be_invalid
          expect(row.errors["Comment"][1]).to include("Comment is required")
        end
      end

      context "when there is also an actual value" do
        it "is invalid" do
          csv_row = valid_csv_row
          allow(csv_row).to receive(:field).and_call_original
          allow(csv_row).to receive(:field).with("Refund Value").and_return("1000.00")
          allow(csv_row).to receive(:field).with("Actual Value").and_return("1000.00")
          row = described_class.new(csv_row)

          expect(row).to be_invalid
        end
        context "when the actual is zero" do
          it "is valid" do
            csv_row = valid_csv_row
            allow(csv_row).to receive(:field).and_call_original
            allow(csv_row).to receive(:field).with("Refund Value").and_return("1000.00")
            allow(csv_row).to receive(:field).with("Actual Value").and_return("0.00")
            row = described_class.new(csv_row)

            expect(row).to be_valid
          end
        end
        context "when the actual is blank" do
          it "is valid" do
            csv_row = valid_csv_row
            allow(csv_row).to receive(:field).and_call_original
            allow(csv_row).to receive(:field).with("Refund Value").and_return("1000.00")
            allow(csv_row).to receive(:field).with("Actual Value").and_return(nil)
            row = described_class.new(csv_row)

            expect(row).to be_valid
          end
        end
      end
    end

    describe "receiving organisation type" do
      context "when the value is on the code list" do
        it "is valid" do
            csv_row = valid_csv_row
            allow(csv_row).to receive(:field).and_call_original
            allow(csv_row).to receive(:field).with("Receiving Organisation Type").and_return("60")
            row = described_class.new(csv_row)

            expect(row).to be_valid
        end
      end
      context "when the value is not on the code list" do
        it "is invalid with an appropriate error" do
            csv_row = valid_csv_row
            allow(csv_row).to receive(:field).and_call_original
            allow(csv_row).to receive(:field).with("Receiving Organisation Type").and_return("not a code")
            row = described_class.new(csv_row)

            expect(row).to be_invalid
            expect(row.errors["Receiving Organisation Type"][1]).to include("valid IATI Organisation Type code")
        end
      end
    end

    describe "activity comments" do
      context "when the row contains a valid activity comment" do
        it "is valid" do
            csv_row = valid_csv_row
            allow(csv_row).to receive(:field).and_call_original
            allow(csv_row).to receive(:field).with("Actual Value").and_return("0.00")
            allow(csv_row).to receive(:field).with("Refund Value").and_return("0.00")
            allow(csv_row).to receive(:field).with("Comment").and_return("This is a valid activity comment")
            row = described_class.new(csv_row)

            expect(row).to be_valid
        end
      end

      context "When the actual and refund values are blank with a comment" do
        it "is invalid with an appropriate message" do
            csv_row = valid_csv_row
            allow(csv_row).to receive(:field).and_call_original
            allow(csv_row).to receive(:field).with("Actual Value").and_return(nil)
            allow(csv_row).to receive(:field).with("Refund Value").and_return(nil)
            allow(csv_row).to receive(:field).with("Comment").and_return("This is a valid activity comment")
            row = described_class.new(csv_row)

            expect(row).to be_invalid
            expect(row.errors["Comment"][1]).to include("must both be zero to provide a comment")
        end
      end

      context "when the actual and refund values are zero without a comment" do
        it "is invalid with an appropriate message" do
            csv_row = valid_csv_row
            allow(csv_row).to receive(:field).and_call_original
            allow(csv_row).to receive(:field).with("Actual Value").and_return("0.00")
            allow(csv_row).to receive(:field).with("Refund Value").and_return("0.00")
            allow(csv_row).to receive(:field).with("Comment").and_return(nil)
            row = described_class.new(csv_row)

            expect(row).to be_invalid
            expect(row.errors["Comment"][1]).to include("with 0 actual and 0 refund require a comment")
        end
      end

      context "when all of the required values are blank" do
        it "is valid" do
            csv_row = valid_csv_row
            allow(csv_row).to receive(:field).and_call_original
            allow(csv_row).to receive(:field).with("Actual Value").and_return(nil)
            allow(csv_row).to receive(:field).with("Refund Value").and_return(nil)
            allow(csv_row).to receive(:field).with("Comment").and_return(nil)
            row = described_class.new(csv_row)

            expect(row).to be_valid
        end
      end
    end
  end

  def valid_csv_row
    CSV::Row.new(
      [
        "Activity RODA Identifier",
        "Financial Quarter",
        "Financial Year",
        "Actual Value",
        "Refund Value",
        "Comment"
      ],
      [
        "A-RODA-IDENTIFIER",
        "3",
        "2023",
        "0",
        "0",
        "This is a comment."
      ]
    )
  end
end
