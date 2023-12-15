require "rails_helper"

RSpec.describe Import::Csv::ActivityActualRefundCommentRow do
  let(:csv_row) { valid_csv_row }

  subject { described_class.new(csv_row) }

  describe "#actual_value" do
    it "returns the value" do
      allow(csv_row).to receive(:field).with("Actual Value").and_return("100000")
      allow(subject).to receive(:actual_value).and_call_original

      expect(subject.actual_value).to eql BigDecimal("100000")
    end
  end

  describe "#refund_value" do
    it "returns the value" do
      allow(csv_row).to receive(:field).with("Refund Value").and_return("100000")
      allow(subject).to receive(:refund_value).and_call_original

      expect(subject.refund_value).to eql BigDecimal("100000")
    end
  end

  describe "#receiving_organisation_name" do
    it "returns the value" do
      allow(csv_row).to receive(:field).with("Receiving Organisation Name").and_return("Organisation Name")

      expect(subject.receiving_organisation_name).to eql "Organisation Name"
    end
  end

  describe "#receiving_organisation_iati_reference" do
    it "returns the value" do
      allow(csv_row).to receive(:field).with("Receiving Organisation IATI Reference").and_return("IATI-REF-01")

      expect(subject.receiving_organisation_iati_reference).to eql "IATI-REF-01"
    end
  end

  describe "#empty?" do
    context "when the row is valid" do
      context "when there is an actual value" do
        it "returns false" do
          allow(csv_row).to receive(:field).with("Comment").and_return(nil)

          allow(subject).to receive(:actual_value).and_return(BigDecimal("10000"))
          allow(subject).to receive(:refund_value).and_return(BigDecimal("0"))

          expect(subject.empty?).to be false
        end
      end

      context "when there is a refund value" do
        it "returns false" do
          allow(csv_row).to receive(:field).with("Comment").and_return("This is a comment.")

          allow(subject).to receive(:actual_value).and_return(BigDecimal("0"))
          allow(subject).to receive(:refund_value).and_return(BigDecimal("10000"))

          expect(subject.empty?).to be false
        end
      end

      context "when there is a comment" do
        it "returns false" do
          allow(csv_row).to receive(:field).with("Comment").and_return("This is a comment.")

          allow(subject).to receive(:actual_value).and_return(BigDecimal("0"))
          allow(subject).to receive(:refund_value).and_return(BigDecimal("0"))

          expect(subject.empty?).to be false
        end
      end

      context "when there are no values of interest" do
        it "returns true" do
          allow(csv_row).to receive(:field).with("Comment").and_return(nil)

          allow(subject).to receive(:actual_value).and_return(BigDecimal("0"))
          allow(subject).to receive(:refund_value).and_return(BigDecimal("0"))

          expect(subject.empty?).to be true
        end
      end
    end

    context "when the row is invalid" do
      it "returns nil" do
        allow(csv_row).to receive(:field).with("Comment").and_return("This is a comment?")

        allow(subject).to receive(:actual_value).and_return(nil)
        allow(subject).to receive(:refund_value).and_return(nil)

        expect(subject.empty?).to be_nil
      end
    end
  end

  describe "#comment" do
    it "returns the comment" do
      allow(csv_row).to receive(:field).with("Actual Value").and_return("0")
      allow(csv_row).to receive(:field).with("Refund Value").and_return("0")
      allow(csv_row).to receive(:field).with("Comment").and_return("This is a comment.")

      expect(subject.comment).to eql "This is a comment."
    end

    context "when the csv cell is nil" do
      it "returns nil" do
        allow(csv_row).to receive(:field).with("Actual Value").and_return("0")
        allow(csv_row).to receive(:field).with("Refund Value").and_return("0")
        allow(csv_row).to receive(:field).with("Comment").and_return(nil)

        expect(subject.comment).to be_nil
      end
    end

    context "when the csv cell is empty" do
      it "returns nil" do
        allow(csv_row).to receive(:field).with("Actual Value").and_return("0")
        allow(csv_row).to receive(:field).with("Refund Value").and_return("0")
        allow(csv_row).to receive(:field).with("Comment").and_return("")

        expect(subject.comment).to be_nil
      end
    end

    context "when the csv cell is a single space" do
      it "returns nil" do
        allow(csv_row).to receive(:field).with("Actual Value").and_return("0")
        allow(csv_row).to receive(:field).with("Refund Value").and_return("0")
        allow(csv_row).to receive(:field).with("Comment").and_return(" ")

        expect(subject.comment).to be_nil
      end
    end

    context "when the csv cell is a multiple spaces" do
      it "returns nil" do
        allow(csv_row).to receive(:field).with("Actual Value").and_return("0")
        allow(csv_row).to receive(:field).with("Refund Value").and_return("0")
        allow(csv_row).to receive(:field).with("Comment").and_return("    ")

        expect(subject.comment).to be_nil
      end
    end
  end

  describe "validations" do
    before do
      allow(subject).to receive(:actual_value).and_return(BigDecimal("0"))
      allow(subject).to receive(:refund_value).and_return(BigDecimal("0"))
    end

    context "when the actual value is zero and the refund value is zero" do
      it "is valid" do
        expect(subject).to be_valid
      end
    end

    context "when the actual value is not a number" do
      it "is invalid with an error message" do
        allow(csv_row).to receive(:field)

        allow(subject).to receive(:actual_value).and_return(nil)
        allow(subject).to receive(:refund_value).and_return(BigDecimal("0"))

        expect(subject).to be_invalid
        expect(error_message_for_column("Actual Value")).to eql "Must be a financial value"
      end
    end

    context "when the actual value is a number" do
      context "and the refund value is zero" do
        context "and there is no comment" do
          it "is valid" do
            allow(csv_row).to receive(:field).with("Comment").and_return(nil)

            allow(subject).to receive(:actual_value).and_return(BigDecimal("10000"))
            allow(subject).to receive(:refund_value).and_return(BigDecimal("0"))

            expect(subject).to be_valid
          end
        end

        context "and there is a comment" do
          it "is valid" do
            allow(csv_row).to receive(:field).with("Comment").and_return("This is a comment.")

            allow(subject).to receive(:actual_value).and_return(BigDecimal("10000"))
            allow(subject).to receive(:refund_value).and_return(BigDecimal("0"))

            expect(subject).to be_valid
          end
        end
      end

      context "and the refund value is a positive number" do
        it "is invalid with an error message" do
          allow(csv_row).to receive(:field)

          allow(subject).to receive(:actual_value).and_return(BigDecimal("10000"))
          allow(subject).to receive(:refund_value).and_return(BigDecimal("20000"))

          expect(subject).to be_invalid
          expect(error_message_for_column("Refund Value")).to include "cannot be reported on the same row"
          expect(error_message_for_column("Actual Value")).to include "cannot be reported on the same row"
        end
      end

      context "and the refund value is a negative number" do
        it "is invalid with an error message" do
          allow(csv_row).to receive(:field)

          allow(subject).to receive(:actual_value).and_return(BigDecimal("10000"))
          allow(subject).to receive(:refund_value).and_return(BigDecimal("-20000"))

          expect(subject).to be_invalid
          expect(error_message_for_column("Refund Value")).to include "cannot be reported on the same row"
          expect(error_message_for_column("Actual Value")).to include "cannot be reported on the same row"
        end
      end
    end

    context "when the refund value is not a number" do
      it "is invalid with an error message" do
        allow(subject).to receive(:actual_value).and_return(BigDecimal("0"))
        allow(subject).to receive(:refund_value).and_return(nil)

        expect(subject).to be_invalid
        expect(error_message_for_column("Refund Value")).to eql "Must be a financial value"
      end
    end

    context "when the refund value is a number" do
      context "and the actual value is zero" do
        context "and there is a comment" do
          it "is valid" do
            allow(csv_row).to receive(:field).with("Comment").and_return("This is a comment.")

            allow(subject).to receive(:actual_value).and_return(BigDecimal("0"))
            allow(subject).to receive(:refund_value).and_return(BigDecimal("10000"))

            expect(subject).to be_valid
          end
        end

        context "and there is no comment" do
          it "is invalid with an error message" do
            allow(csv_row).to receive(:field).with("Comment").and_return(nil)

            allow(subject).to receive(:actual_value).and_return(BigDecimal("0"))
            allow(subject).to receive(:refund_value).and_return(BigDecimal("10000"))

            expect(subject).to be_invalid
            expect(error_message_for_column("Comment")).to eql "Refund must have a comment"
          end
        end
      end

      context "and the actual value is a positive number" do
        it "is invalid" do
          allow(csv_row).to receive(:field)

          allow(subject).to receive(:actual_value).and_return(BigDecimal("20000"))
          allow(subject).to receive(:refund_value).and_return(BigDecimal("10000"))

          expect(subject).to be_invalid
          expect(error_message_for_column("Refund Value")).to include "cannot be reported on the same row"
          expect(error_message_for_column("Actual Value")).to include "cannot be reported on the same row"
        end
      end
    end

    context "when the actual and refund are zero" do
      context "and there is a comment" do
        it "is valid" do
          allow(csv_row).to receive(:field).with("Comment").and_return("This is a comment.")

          expect(subject).to be_valid
        end
      end

      context "and there is not a comment" do
        it "is valid" do
          allow(csv_row).to receive(:field).with("Comment").and_return(nil)

          expect(subject).to be_valid
        end
      end
    end

    describe "financial quarter" do
      context "when the value is blank" do
        it "is invalid with an error message" do
          allow(csv_row).to receive(:field).with("Financial Quarter").and_return(nil)

          expect(subject).to be_invalid
          expect(error_message_for_column("Financial Quarter")).to eql "Is required"
        end
      end

      context "when the value is no 1, 2, 3 or 4" do
        it "is invalid with an error message" do
          allow(csv_row).to receive(:field).with("Financial Quarter").and_return("5")

          expect(subject).to be_invalid
          expect(error_message_for_column("Financial Quarter")).to eql "Must be 1, 2, 3 or 4"
        end
      end
    end

    describe "financial year" do
      context "when the value is blank" do
        it "is invalid with an error message" do
          allow(csv_row).to receive(:field).with("Financial Year").and_return(nil)

          expect(subject).to be_invalid
          expect(error_message_for_column("Financial Year")).to eql "Is required"
        end
      end

      context "when the year is not valid" do
        it "is invalid with an error message" do
          allow(csv_row).to receive(:field).with("Financial Year").and_return("Twenty twenty three")

          expect(subject).to be_invalid
          expect(error_message_for_column("Financial Year")).to eql "Must be a four digit year"
        end
      end
    end

    describe "RODA identifier" do
      context "when the value is blank" do
        it "is invalid with an error message" do
          allow(csv_row).to receive(:field).with("Activity RODA Identifier").and_return(nil)

          expect(subject).to be_invalid
          expect(error_message_for_column("Activity RODA Identifier")).to eql "Is required"
        end
      end
    end

    describe "Receiving Organisation Type" do
      context "when the value is blank" do
        it "is valid" do
          allow(csv_row).to receive(:field).with("Receiving Organisation Type").and_return(nil)

          expect(subject).to be_valid
        end
      end

      context "when the value is on the code list" do
        it "is valid" do
          allow(csv_row).to receive(:field).with("Receiving Organisation Type").and_return("10")

          expect(subject).to be_valid
        end
      end

      context "when the value is not on the code list" do
        it "is invalid" do
          allow(csv_row).to receive(:field).with("Receiving Organisation Type").and_return("Not a code")

          expect(subject).to be_invalid
          expect(error_message_for_column("Receiving Organisation Type")).to include "must be a valid IATI Organisation Type code"
        end
      end
    end
  end

  def valid_csv_row
    row = double(CSV::Row)
    allow(row).to receive(:field).with("Activity RODA Identifier").and_return("GCRF-UKSA-DJ94DSK0-ID")
    allow(row).to receive(:field).with("Financial Quarter").and_return("1")
    allow(row).to receive(:field).with("Financial Year").and_return("2023")
    allow(row).to receive(:field).with("Actual Value").and_return("10000")
    allow(row).to receive(:field).with("Refund Value").and_return("20000")
    allow(row).to receive(:field).with("Comment").and_return("This is a comment.")
    allow(row).to receive(:field).with("Receiving Organisation Name").and_return(nil)
    allow(row).to receive(:field).with("Receiving Organisation IATI Reference").and_return(nil)
    allow(row).to receive(:field).with("Receiving Organisation Type").and_return(nil)

    row
  end

  def error_message_for_column(column_header)
    subject.errors[column_header][1]
  end
end
