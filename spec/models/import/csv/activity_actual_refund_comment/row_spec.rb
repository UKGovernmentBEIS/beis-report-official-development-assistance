require "rails_helper"

RSpec.describe Import::Csv::ActivityActualRefundComment::Row do
  subject { described_class.new(csv_row) }

  describe "#actual_value" do
    context "when the row is valid" do
      let(:csv_row) { valid_csv_row(actual: "10000", refund: "0", comment: "") }

      it "returns the converted value" do
        expect(subject.actual_value).to eql BigDecimal("10000")
      end
    end
  end

  describe "#refund_value" do
    context "when the row is valid" do
      let(:csv_row) { valid_csv_row(actual: "0", refund: "20000", comment: "This is a refund.") }

      it "returns the converted value" do
        expect(subject.refund_value).to eql BigDecimal("20000")
      end
    end
  end

  describe "#roda_identifier" do
    let(:csv_row) { valid_csv_row }

    context "when the value is a string" do
      it "returns the string" do
        allow(csv_row).to receive(:field).with("Activity RODA Identifier").and_return("VALID-RODA-IDENTIFIER")

        expect(subject.roda_identifier).to eql "VALID-RODA-IDENTIFIER"
      end
    end

    context "when the value is nil" do
      it "returns nil" do
        allow(csv_row).to receive(:field).with("Activity RODA Identifier").and_return(nil)

        expect(subject.roda_identifier).to be_nil
      end
    end

    context "when the value is blank" do
      it "returns nil" do
        allow(csv_row).to receive(:field).with("Activity RODA Identifier").and_return("")

        expect(subject.roda_identifier).to be_nil
      end
    end
  end

  describe "#financial_quarter" do
    let(:csv_row) { valid_csv_row }

    context "when the value is a string" do
      it "returns the string" do
        allow(csv_row).to receive(:field).with("Financial Quarter").and_return("2")

        expect(subject.financial_quarter).to eql "2"
      end
    end

    context "when the value is nil" do
      it "returns nil" do
        allow(csv_row).to receive(:field).with("Financial Quarter").and_return(nil)

        expect(subject.financial_quarter).to be_nil
      end
    end

    context "when the value is blank" do
      it "returns nil" do
        allow(csv_row).to receive(:field).with("Financial Quarter").and_return("")

        expect(subject.financial_quarter).to be_nil
      end
    end
  end

  describe "#financial_year" do
    let(:csv_row) { valid_csv_row }

    context "when the value is a string" do
      it "returns the string" do
        allow(csv_row).to receive(:field).with("Financial Year").and_return("2023")

        expect(subject.financial_year).to eql "2023"
      end
    end

    context "when the value is nil" do
      it "returns nil" do
        allow(csv_row).to receive(:field).with("Financial Year").and_return(nil)

        expect(subject.financial_year).to be_nil
      end
    end

    context "when the value is blank" do
      it "returns nil" do
        allow(csv_row).to receive(:field).with("Financial Year").and_return("")

        expect(subject.financial_year).to be_nil
      end
    end
  end

  describe "#receiving_organisation_name" do
    let(:csv_row) { valid_csv_row }

    context "when the value is a string" do
      it "returns the string" do
        allow(csv_row).to receive(:field).with("Receiving Organisation Name").and_return("Organisation Name")

        expect(subject.receiving_organisation_name).to eql "Organisation Name"
      end
    end

    context "when the value is nil" do
      it "returns nil" do
        allow(csv_row).to receive(:field).with("Receiving Organisation Name").and_return(nil)

        expect(subject.receiving_organisation_name).to be_nil
      end
    end

    context "when the value is blank" do
      it "returns nil" do
        allow(csv_row).to receive(:field).with("Receiving Organisation Name").and_return("     ")

        expect(subject.receiving_organisation_name).to be_nil
      end
    end
  end

  describe "#receiving_organisation_type" do
    let(:csv_row) { valid_csv_row }

    context "when the value is a string" do
      it "returns the string" do
        allow(csv_row).to receive(:field).with("Receiving Organisation Type").and_return("10")

        expect(subject.receiving_organisation_type).to eql "10"
      end
    end

    context "when the value is nil" do
      it "returns nil" do
        allow(csv_row).to receive(:field).with("Receiving Organisation Type").and_return(nil)

        expect(subject.receiving_organisation_type).to be_nil
      end
    end

    context "when the value is blank" do
      it "returns nil" do
        allow(csv_row).to receive(:field).with("Receiving Organisation Type").and_return("     ")

        expect(subject.receiving_organisation_type).to be_nil
      end
    end
  end

  describe "#receiving_organisation_iati_reference" do
    let(:csv_row) { valid_csv_row }

    context "when there is a string" do
      it "returns the value" do
        allow(csv_row).to receive(:field).with("Receiving Organisation IATI Reference").and_return("IATI-REF-01")

        expect(subject.receiving_organisation_iati_reference).to eql "IATI-REF-01"
      end
    end

    context "when the value is nil" do
      it "returns nil" do
        allow(csv_row).to receive(:field).with("Receiving Organisation IATI Reference").and_return(nil)

        expect(subject.receiving_organisation_iati_reference).to be_nil
      end
    end

    context "when the value is blank" do
      it "returns nil" do
        allow(csv_row).to receive(:field).with("Receiving Organisation IATI Reference").and_return("   ")

        expect(subject.receiving_organisation_iati_reference).to be_nil
      end
    end
  end

  describe "#empty?" do
    context "when the row is valid" do
      context "when there is an actual value" do
        let(:csv_row) { valid_csv_row(actual: "30000", refund: "0", comment: "") }

        it "returns false" do
          expect(subject.empty?).to be false
        end
      end

      context "when there is a refund value" do
        let(:csv_row) { valid_csv_row(actual: "0", refund: "40000", comment: "This is a refund.") }

        it "returns false" do
          expect(subject.empty?).to be false
        end
      end

      context "when there is a comment" do
        let(:csv_row) { valid_csv_row(actual: "0", refund: "0", comment: "This is a comment.") }

        it "returns false" do
          expect(subject.empty?).to be false
        end
      end

      context "when there are no values of interest" do
        let(:csv_row) { valid_csv_row(actual: "0", refund: "0", comment: "") }

        it "returns true" do
          expect(subject.empty?).to be true
        end
      end
    end

    context "when the row is invalid" do
      let(:csv_row) { valid_csv_row(actual: "ten thousand pounds", refund: "0", comment: "") }

      it "returns nil" do
        expect(subject.empty?).to be_nil
      end
    end
  end

  describe "#comment" do
    context "when there is a comment" do
      let(:csv_row) { valid_csv_row(actual: "", refund: "", comment: "This is a comment.") }

      it "returns the comment" do
        expect(subject.comment).to eql "This is a comment."
      end
    end

    context "when the comment is blank" do
      let(:csv_row) { valid_csv_row(actual: "", refund: "", comment: nil) }

      it "returns nil" do
        expect(subject.comment).to be_nil
      end
    end

    context "when the comment is empty" do
      let(:csv_row) { valid_csv_row(actual: "", refund: "", comment: nil) }

      it "returns nil" do
        expect(subject.comment).to be_nil
      end
    end

    context "when the commnet is a single space" do
      let(:csv_row) { valid_csv_row(actual: "", refund: "", comment: " ") }

      it "returns nil" do
        expect(subject.comment).to be_nil
      end
    end

    context "when the comment is a multiple spaces" do
      let(:csv_row) { valid_csv_row(actual: "", refund: "", comment: "     ") }

      it "returns nil" do
        expect(subject.comment).to be_nil
      end
    end
  end

  describe "validations" do
    context "when the actual value is zero and the refund value is zero" do
      let(:csv_row) { valid_csv_row(actual: "0", refund: "0", comment: "") }

      it "is valid" do
        expect(subject).to be_valid
      end
    end

    context "when the actual value is not a number" do
      let(:csv_row) { valid_csv_row(actual: "ten thousand pounds", refund: "0", comment: "") }

      it "is invalid with an error message and the original value" do
        expect(subject).to be_invalid
        expect(error_for_column("Actual Value").message).to eql "Must be a financial value"
        expect(error_for_column("Actual Value").value).to eql "ten thousand pounds"
      end
    end

    context "when the actual value is a number" do
      context "and the refund value is zero" do
        context "and there is no comment" do
          let(:csv_row) { valid_csv_row(actual: "10000", refund: "0", comment: "") }

          it "is valid" do
            expect(subject).to be_valid
          end
        end

        context "and there is a comment" do
          let(:csv_row) { valid_csv_row(actual: "10000", refund: "0", comment: "This is a comment.") }

          it "is valid" do
            expect(subject).to be_valid
          end
        end
      end

      context "and the refund value is a positive number" do
        let(:csv_row) { valid_csv_row(actual: "30000", refund: "40000", comment: "") }

        it "is invalid with an error message and the original value" do
          expect(subject).to be_invalid
          expect(error_for_column("Actual Value").message).to include "cannot be reported on the same row"
          expect(error_for_column("Actual Value").value).to eql "30000"
          expect(error_for_column("Refund Value").message).to include "cannot be reported on the same row"
          expect(error_for_column("Refund Value").value).to eql "40000"
        end
      end

      context "and the refund value is a negative number" do
        let(:csv_row) { valid_csv_row(actual: "30000", refund: "-40000", comment: "") }

        it "is invalid with an error message and the original value" do
          expect(subject).to be_invalid
          expect(error_for_column("Actual Value").message).to include "cannot be reported on the same row"
          expect(error_for_column("Actual Value").value).to eql "30000"
          expect(error_for_column("Refund Value").message).to include "cannot be reported on the same row"
          expect(error_for_column("Refund Value").value).to eql "-40000"
        end
      end
    end

    context "when the refund value is not a number" do
      let(:csv_row) { valid_csv_row(actual: "30000", refund: "zero", comment: "") }

      it "is invalid with an error message and the original value" do
        expect(subject).to be_invalid
        expect(error_for_column("Refund Value").message).to eql "Must be a financial value"
        expect(error_for_column("Refund Value").value).to eql "zero"
      end
    end

    context "when the refund value is a number" do
      context "and the actual value is zero" do
        context "and there is a comment" do
          let(:csv_row) { valid_csv_row(actual: "0", refund: "10000", comment: "This is a refund comment.") }

          it "is valid" do
            expect(subject).to be_valid
          end
        end

        context "and there is no comment" do
          let(:csv_row) { valid_csv_row(actual: "0", refund: "10000", comment: "") }

          it "is invalid with an error message and the original value" do
            expect(subject).to be_invalid
            expect(error_for_column("Comment").message).to eql "Refund must have a comment"
            expect(error_for_column("Comment").value).to be_nil
          end
        end
      end

      context "and the actual value is a positive number" do
        let(:csv_row) { valid_csv_row(actual: "50000", refund: "10000", comment: "This is a refund comment.") }

        it "is invalid with an error message and the original value" do
          expect(subject).to be_invalid
          expect(error_for_column("Actual Value").message).to include "cannot be reported on the same row"
          expect(error_for_column("Actual Value").value).to eql "50000"
          expect(error_for_column("Refund Value").message).to include "cannot be reported on the same row"
          expect(error_for_column("Refund Value").value).to eql "10000"
        end
      end
    end

    context "when the actual and refund are zero" do
      context "and there is a comment" do
        let(:csv_row) { valid_csv_row(actual: "0", refund: "0", comment: "This is a activity comment.") }

        it "is valid" do
          expect(subject).to be_valid
        end
      end

      context "and there is not a comment" do
        let(:csv_row) { valid_csv_row(actual: "0", refund: "0", comment: "") }

        it "is valid" do
          expect(subject).to be_valid
        end
      end
    end

    describe "financial quarter" do
      let(:csv_row) { valid_csv_row }

      context "when the value is nil" do
        it "is invalid with an error message and the original value" do
          allow(csv_row).to receive(:field).with("Financial Quarter").and_return(nil)

          expect(subject).to be_invalid
          expect(error_for_column("Financial Quarter").message).to eql "Is required"
          expect(error_for_column("Financial Quarter").value).to eql nil
        end
      end

      context "when the value is blank" do
        it "is invalid with an error message and the original value" do
          allow(csv_row).to receive(:field).with("Financial Quarter").and_return("")

          expect(subject).to be_invalid
          expect(error_for_column("Financial Quarter").message).to eql "Is required"
          expect(error_for_column("Financial Quarter").value).to be_nil
        end
      end

      context "when the value is not 1, 2, 3 or 4" do
        it "is invalid with an error message and the original value" do
          allow(csv_row).to receive(:field).with("Financial Quarter").and_return("5")

          expect(subject).to be_invalid
          expect(error_for_column("Financial Quarter").message).to eql "Must be 1, 2, 3 or 4"
          expect(error_for_column("Financial Quarter").value).to eql "5"
        end
      end
    end

    describe "financial year" do
      let(:csv_row) { valid_csv_row }

      context "when the value is nil" do
        it "is invalid with an error message and the original value" do
          allow(csv_row).to receive(:field).with("Financial Year").and_return(nil)

          expect(subject).to be_invalid
          expect(error_for_column("Financial Year").message).to eql "Is required"
          expect(error_for_column("Financial Year").value).to eql nil
        end
      end

      context "when the value is blank" do
        it "is invalid with an error message and the original value" do
          allow(csv_row).to receive(:field).with("Financial Year").and_return("")

          expect(subject).to be_invalid
          expect(error_for_column("Financial Year").message).to eql "Is required"
          expect(error_for_column("Financial Year").value).to be_nil
        end
      end

      context "when the year is not valid" do
        it "is invalid with an error message and the original value" do
          allow(csv_row).to receive(:field).with("Financial Year").and_return("Twenty twenty three")

          expect(subject).to be_invalid
          expect(error_for_column("Financial Year").message).to eql "Must be a four digit year"
          expect(error_for_column("Financial Year").value).to eql "Twenty twenty three"
        end
      end
    end

    describe "RODA identifier" do
      let(:csv_row) { valid_csv_row }

      context "when the value is nil" do
        it "is invalid with an error message and the original value" do
          allow(csv_row).to receive(:field).with("Activity RODA Identifier").and_return(nil)

          expect(subject).to be_invalid
          expect(error_for_column("Activity RODA Identifier").message).to eql "Is required"
          expect(error_for_column("Activity RODA Identifier").value).to be_nil
        end
      end

      context "when the value is blank" do
        it "is invalid with an error message and the original value" do
          allow(csv_row).to receive(:field).with("Activity RODA Identifier").and_return("")

          expect(subject).to be_invalid
          expect(error_for_column("Activity RODA Identifier").message).to eql "Is required"
          expect(error_for_column("Activity RODA Identifier").value).to be_nil
        end
      end
    end

    describe "Receiving Organisation" do
      let(:csv_row) { valid_csv_row }

      context "when the name is blank" do
        context "and the the type and IATI reference are also blank" do
          it "is valid" do
            allow(csv_row).to receive(:field).with("Receiving Organisation Name").and_return("")
            allow(csv_row).to receive(:field).with("Receiving Organisation Type").and_return("")
            allow(csv_row).to receive(:field).with("Receiving Organisation IATI Reference").and_return("")

            expect(subject).to be_valid
          end
        end

        context "and the type has a value but the IATI reference does not" do
          it "is invalid with an error message and the original value" do
            allow(csv_row).to receive(:field).with("Receiving Organisation Name").and_return("")
            allow(csv_row).to receive(:field).with("Receiving Organisation Type").and_return("10")
            allow(csv_row).to receive(:field).with("Receiving Organisation IATI Reference").and_return("")

            expect(subject).to be_invalid
            expect(error_for_column("Receiving Organisation Name").message).to include("Cannot be blank when")
            expect(error_for_column("Receiving Organisation Name").value).to be_nil
          end
        end

        context "and the IATI reference has a value but the type does not" do
          it "is invalid an error message and the original value" do
            allow(csv_row).to receive(:field).with("Receiving Organisation Name").and_return("")
            allow(csv_row).to receive(:field).with("Receiving Organisation Type").and_return("")
            allow(csv_row).to receive(:field).with("Receiving Organisation IATI Reference").and_return("IATI-REF")

            expect(subject).to be_invalid
            expect(error_for_column("Receiving Organisation Name").message).to include("Cannot be blank when")
            expect(error_for_column("Receiving Organisation Name").value).to be_nil
          end
        end
      end

      context "when the name has a value" do
        context "and the type and IATI reference are blank" do
          it "is invalid with an error message and the original value" do
            allow(csv_row).to receive(:field).with("Receiving Organisation Name").and_return("Test organisation")
            allow(csv_row).to receive(:field).with("Receiving Organisation Type").and_return("")
            allow(csv_row).to receive(:field).with("Receiving Organisation IATI Reference").and_return("")

            expect(subject).to be_invalid
            expect(error_for_column("Receiving Organisation Type").message).to include("Cannot be blank when")
            expect(error_for_column("Receiving Organisation Type").value).to be_nil
          end
        end

        context "and the type has a valid value but the IATI reference is blank" do
          it "is valid" do
            allow(csv_row).to receive(:field).with("Receiving Organisation Name").and_return("Test organisation")
            allow(csv_row).to receive(:field).with("Receiving Organisation Type").and_return("10")
            allow(csv_row).to receive(:field).with("Receiving Organisation IATI Reference").and_return("")

            expect(subject).to be_valid
          end
        end

        context "and the IATI reference has a value but the type does not" do
          it "is invalid with an error message and the original value" do
            allow(csv_row).to receive(:field).with("Receiving Organisation Name").and_return("Test organisation")
            allow(csv_row).to receive(:field).with("Receiving Organisation Type").and_return("")
            allow(csv_row).to receive(:field).with("Receiving Organisation IATI Reference").and_return("IATI-REF")

            expect(subject).to be_invalid
            expect(error_for_column("Receiving Organisation Type").message).to include("Cannot be blank when")
            expect(error_for_column("Receiving Organisation Type").value).to be_nil
          end
        end
      end
    end

    describe "Receiving Organisation Type" do
      let(:csv_row) { valid_csv_row }

      context "when the value is on the code list" do
        it "is valid" do
          allow(csv_row).to receive(:field).with("Receiving Organisation Name").and_return("Test Organisation")
          allow(csv_row).to receive(:field).with("Receiving Organisation Type").and_return("10")

          expect(subject).to be_valid
        end
      end

      context "when the value is not on the code list" do
        it "is invalid with an error message and the original value" do
          allow(csv_row).to receive(:field).with("Receiving Organisation Name").and_return("Test Organisation")
          allow(csv_row).to receive(:field).with("Receiving Organisation Type").and_return("Not a code")

          expect(subject).to be_invalid
          expect(error_for_column("Receiving Organisation Type").message).to include "valid receiving organisation type code"
          expect(error_for_column("Receiving Organisation Type").value).to include "Not a code"
        end
      end
    end
  end

  def valid_csv_row(actual: "10000", refund: "0", comment: "This is a comment")
    row = double(CSV::Row)
    allow(row).to receive(:field).with("Activity RODA Identifier").and_return("GCRF-UKSA-DJ94DSK0-ID")
    allow(row).to receive(:field).with("Financial Quarter").and_return("1")
    allow(row).to receive(:field).with("Financial Year").and_return("2023")
    allow(row).to receive(:field).with("Actual Value").and_return(actual)
    allow(row).to receive(:field).with("Refund Value").and_return(refund)
    allow(row).to receive(:field).with("Comment").and_return(comment)
    allow(row).to receive(:field).with("Receiving Organisation Name").and_return(nil)
    allow(row).to receive(:field).with("Receiving Organisation IATI Reference").and_return(nil)
    allow(row).to receive(:field).with("Receiving Organisation Type").and_return(nil)

    row
  end

  def error_for_column(column_header)
    raise "No error for column #{column_header}" unless subject.errors[column_header]

    message = subject.errors[column_header][1]
    value = subject.errors[column_header][0]

    OpenStruct.new(value: value, message: message)
  end
end
