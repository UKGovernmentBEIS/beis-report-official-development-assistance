require "rails_helper"

RSpec.describe Import::Csv::ActivityActualRefundComment::RowService, type: :import_csv do
  let(:report) { double(Report) }
  let(:user) { double(User) }
  let(:organisation) { double(Organisation, default_currency: "GBP") }
  let(:fund) { double(Fund) }
  let(:activity) { double(Activity) }

  let(:valid_actual) { double(Actual, errors: [], save!: true) }
  let(:invalid_actual) { double(Actual, errors: [double(attribute: "value", message: "Value must not be zero")], save!: false) }

  let(:valid_refund) { double(Refund, errors: [], save!: true) }
  let(:invalid_refund) { double(Refund, errors: [double(attribute: "value", message: "Value must not be zero")], save!: false) }

  let(:valid_comment) { double(Comment, errors: [], save!: true) }
  let(:invalid_comment) { double(Comment, errors: [double(attribute: "body", message: "Cannot be blank")], save!: false) }

  let(:authorised_policy) { double(ActivityPolicy, create?: true) }
  let(:unauthorised_policy) { double(ActivityPolicy, create?: false) }

  subject { described_class.new(report, user, csv_row) }

  describe "#import!" do
    context "when the row is for an actual" do
      context "and the row is valid" do
        let(:csv_row) { valid_csv_row(actual: "10000", refund: "0", comment: "") }

        it "returns the actual record" do
          allow(activity).to receive(:providing_organisation).and_return(organisation)
          allow(activity).to receive(:title).and_return("A test activity")

          allow(subject).to receive(:find_activity).and_return(activity)
          allow(subject).to receive(:authorise_activity).and_return(true)

          creator = double(CreateActual)
          allow(CreateActual).to receive(:new).and_return(creator)
          allow(creator).to receive(:call).and_return(Result.new(true, valid_actual))

          result = subject.import!

          expect(result).to eql valid_actual
        end

        it "assigns the default values" do
          allow(activity).to receive(:providing_organisation).and_return(organisation)
          allow(activity).to receive(:title).and_return("A test activity")

          allow(subject).to receive(:find_activity).and_return(activity)
          allow(subject).to receive(:authorise_activity).and_return(true)

          creator = double(CreateActual)
          allow(CreateActual).to receive(:new).and_return(creator)
          allow(creator).to receive(:call).and_return(Result.new(true, valid_actual))

          subject.import!

          expected_attributes = {
            comment: nil,
            currency: "GBP",
            description: "FQ1 2023-2024 spend on A test activity",
            financial_quarter: "1",
            financial_year: "2023",
            value: BigDecimal(10000),
            receiving_organisation_name: nil,
            receiving_organisation_type: nil,
            receiving_organisation_reference: nil
          }

          expect(creator).to have_received(:call).with(attributes: expected_attributes)
        end

        context "and there is a receiving organisation" do
          it "assigns the receiving organisation attributes" do
            allow(csv_row).to receive(:field).with("Receiving Organisation Name").and_return("Receiving Organisation")
            allow(csv_row).to receive(:field).with("Receiving Organisation Type").and_return("10")
            allow(csv_row).to receive(:field).with("Receiving Organisation IATI Reference").and_return("IATI-RO-01")

            allow(activity).to receive(:providing_organisation).and_return(organisation)
            allow(activity).to receive(:title).and_return("A test activity")

            allow(subject).to receive(:find_activity).and_return(activity)
            allow(subject).to receive(:authorise_activity).and_return(true)

            creator = double(CreateActual)
            allow(CreateActual).to receive(:new).and_return(creator)
            allow(creator).to receive(:call).and_return(Result.new(true, valid_actual))

            subject.import!

            expected_attributes = {
              comment: nil,
              currency: "GBP",
              description: "FQ1 2023-2024 spend on A test activity",
              financial_quarter: "1",
              financial_year: "2023",
              value: BigDecimal(10000),
              receiving_organisation_name: "Receiving Organisation",
              receiving_organisation_type: "10",
              receiving_organisation_reference: "IATI-RO-01"
            }

            expect(creator).to have_received(:call).with(attributes: expected_attributes)
          end
        end

        context "and the actual cannot be saved" do
          it "returns false with errors" do
            allow(subject).to receive(:find_activity).and_return(activity)
            allow(subject).to receive(:authorise_activity).and_return(true)
            allow(subject).to receive(:type_of_row).and_return(:actual)
            allow(subject).to receive(:create_actual).and_return(Result.new(false, invalid_actual))

            result = subject.import!
            errors = subject.errors

            expect(result).to be false

            expect(errors.count).to be 1
            expect(error_for_attribute(errors, "value").attribute).to eql "value"
            expect(error_for_attribute(errors, "value").message).to eql "Value must not be zero"
          end
        end
      end

      context "when the row is not valid" do
        let(:csv_row) { valid_csv_row(actual: "10000", refund: "20000", comment: "") }

        it "returns false with errors" do
          allow(subject).to receive(:find_activity).and_return(activity)
          allow(subject).to receive(:authorise_activity).and_return(true)

          result = subject.import!
          errors = subject.errors

          expect(result).to be false

          expect(errors.count).to be 2
          expect(error_for_attribute(errors, "Actual Value").message).to include "cannot be reported on the same row"
          expect(error_for_attribute(errors, "Actual Value").value).to eql "10000"
          expect(error_for_attribute(errors, "Refund Value").message).to include "cannot be reported on the same row"
          expect(error_for_attribute(errors, "Refund Value").value).to eql "20000"
        end
      end

      context "when the type of row cannot be identified" do
        let(:csv_row) { valid_csv_row }

        it "returns false without errors" do
          allow(subject).to receive(:find_activity).and_return(activity)
          allow(subject).to receive(:authorise_activity).and_return(true)
          allow(subject).to receive(:type_of_row).and_return(nil)

          result = subject.import!
          errors = subject.errors

          expect(result).to be false
          expect(errors.count).to be_zero
        end
      end
    end

    context "when the row is for a refund" do
      context "and the row is valid" do
        let(:csv_row) { valid_csv_row(actual: "0", refund: "30000", comment: "This is a refund comment.") }

        it "returns the refund" do
          allow(activity).to receive(:providing_organisation).and_return(organisation)
          allow(activity).to receive(:title).and_return("A test activity")

          allow(subject).to receive(:find_activity).and_return(activity)
          allow(subject).to receive(:authorise_activity).and_return(true)

          creator = double(CreateRefund)
          allow(CreateRefund).to receive(:new).and_return(creator)
          allow(creator).to receive(:call).and_return(Result.new(true, valid_refund))

          result = subject.import!

          expect(result).to eql valid_refund
        end

        it "assigns the default values" do
          allow(activity).to receive(:providing_organisation).and_return(organisation)
          allow(activity).to receive(:title).and_return("A test activity")

          allow(subject).to receive(:find_activity).and_return(activity)
          allow(subject).to receive(:authorise_activity).and_return(true)

          creator = double(CreateRefund)
          allow(CreateRefund).to receive(:new).and_return(creator)
          allow(creator).to receive(:call).and_return(Result.new(true, valid_refund))

          subject.import!

          expected_attributes = {
            comment: "This is a refund comment.",
            currency: "GBP",
            description: "FQ1 2023-2024 refund from A test activity",
            financial_quarter: "1",
            financial_year: "2023",
            value: BigDecimal(30000),
            receiving_organisation_name: nil,
            receiving_organisation_type: nil,
            receiving_organisation_reference: nil
          }

          expect(creator).to have_received(:call).with(attributes: expected_attributes)
        end

        context "and there is a receiving organisation" do
          it "assigns the receiving organisation attributes" do
            allow(csv_row).to receive(:field).with("Receiving Organisation Name").and_return("Receiving Organisation")
            allow(csv_row).to receive(:field).with("Receiving Organisation Type").and_return("10")
            allow(csv_row).to receive(:field).with("Receiving Organisation IATI Reference").and_return("IATI-RO-01")

            allow(activity).to receive(:providing_organisation).and_return(organisation)
            allow(activity).to receive(:title).and_return("A test activity")

            allow(subject).to receive(:find_activity).and_return(activity)
            allow(subject).to receive(:authorise_activity).and_return(true)

            creator = double(CreateRefund)
            allow(CreateRefund).to receive(:new).and_return(creator)
            allow(creator).to receive(:call).and_return(Result.new(true, valid_refund))

            subject.import!

            expected_attributes = {
              comment: "This is a refund comment.",
              currency: "GBP",
              description: "FQ1 2023-2024 refund from A test activity",
              financial_quarter: "1",
              financial_year: "2023",
              value: BigDecimal(30000),
              receiving_organisation_name: "Receiving Organisation",
              receiving_organisation_type: "10",
              receiving_organisation_reference: "IATI-RO-01"
            }

            expect(creator).to have_received(:call).with(attributes: expected_attributes)
          end
        end

        context "and the refund cannot be saved" do
          it "returns false with the error" do
            allow(subject).to receive(:find_activity).and_return(activity)
            allow(subject).to receive(:authorise_activity).and_return(true)
            allow(subject).to receive(:type_of_row).and_return(:refund)
            allow(subject).to receive(:create_refund).and_return(Result.new(false, invalid_refund))

            result = subject.import!
            errors = subject.errors

            expect(result).to be false

            expect(errors.count).to be 1
            expect(error_for_attribute(errors, "value").attribute).to eql "value"
            expect(error_for_attribute(errors, "value").message).to eql "Value must not be zero"
          end
        end
      end

      context "when the row is not valid" do
        let(:csv_row) { valid_csv_row(actual: "20000", refund: "30000", comment: "This is a refund comment.") }

        it "returns false with errors" do
          allow(subject).to receive(:find_activity).and_return(activity)
          allow(subject).to receive(:authorise_activity).and_return(true)

          result = subject.import!
          errors = subject.errors

          expect(result).to be false

          expect(errors.count).to be 2
          expect(error_for_attribute(errors, "Actual Value").message).to include "cannot be reported on the same row"
          expect(error_for_attribute(errors, "Actual Value").value).to eql "20000"
          expect(error_for_attribute(errors, "Refund Value").message).to include "cannot be reported on the same row"
          expect(error_for_attribute(errors, "Refund Value").value).to eql "30000"
        end
      end
    end

    context "when the row is for an activity comment" do
      context "and the row is valid" do
        let(:csv_row) { valid_csv_row(actual: "0", refund: "0", comment: "This is a activity comment.") }

        it "returns the comment record" do
          allow(subject).to receive(:find_activity).and_return(activity)
          allow(subject).to receive(:authorise_activity).and_return(true)

          allow(Comment).to receive(:new).and_return(valid_comment)

          result = subject.import!

          expect(result).to eql valid_comment
        end

        context "and the activity comment cannot be saved" do
          it "returns false with the error" do
            allow(subject).to receive(:find_activity).and_return(activity)
            allow(subject).to receive(:authorise_activity).and_return(true)
            allow(subject).to receive(:type_of_row).and_return(:comment)
            allow(subject).to receive(:create_activity_comment).and_return(Result.new(false, invalid_comment))

            result = subject.import!
            errors = subject.errors

            expect(result).to be false

            expect(errors.count).to be 1
            expect(error_for_attribute(errors, "body").attribute).to eql "body"
            expect(error_for_attribute(errors, "body").message).to eql "Cannot be blank"
          end
        end
      end

      context "when the row is not valid" do
        let(:csv_row) { valid_csv_row(actual: "40000", refund: "50000", comment: "This is a activity comment.") }

        it "returns false with errors" do
          allow(subject).to receive(:find_activity).and_return(activity)
          allow(subject).to receive(:authorise_activity).and_return(true)
          allow(subject).to receive(:type_of_row).and_return(:comment)
          allow(subject).to receive(:create_activity_comment).and_return(Result.new(false, valid_comment))

          result = subject.import!
          errors = subject.errors

          expect(result).to be false

          expect(errors.count).to be 2
          expect(error_for_attribute(errors, "Actual Value").message).to include "cannot be reported on the same row"
          expect(error_for_attribute(errors, "Actual Value").value).to eql "40000"
          expect(error_for_attribute(errors, "Refund Value").message).to include "cannot be reported on the same row"
          expect(error_for_attribute(errors, "Refund Value").value).to eql "50000"
        end
      end
    end

    context "when the activity cannot be found" do
      let(:csv_row) { valid_csv_row }

      it "returns false with an error" do
        allow(Activity).to receive(:find_by_roda_identifier).and_return(nil)

        result = subject.import!
        errors = subject.errors

        expect(result).to be false

        expect(errors.count).to be 1
        expect(error_for_attribute(errors, "Activity RODA Identifier").message).to eql "Cannot be found"
      end
    end

    context "when the row is empty" do
      let(:csv_row) { valid_csv_row(actual: "0", refund: "0", comment: "") }

      it "returns a skipped row instance" do
        row = double(
          Import::Csv::ActivityActualRefundComment::Row,
          valid?: true,
          empty?: true,
          roda_identifier: "VALID-RODA-IDENTIFIER",
          financial_quarter: "2",
          financial_year: "2023"
        )
        allow(Import::Csv::ActivityActualRefundComment::Row).to receive(:new).and_return(row)

        allow(subject).to receive(:find_activity).and_return(activity)
        allow(subject).to receive(:authorise_activity).and_return(true)

        result = subject.import!
        errors = subject.errors

        expect(errors.count).to be_zero

        expect(result).to be_a Import::Csv::ActivityActualRefundComment::SkippedRow
        expect(result.roda_identifier).to eql "VALID-RODA-IDENTIFIER"
        expect(result.financial_quarter).to eql "2"
        expect(result.financial_year).to eql "2023"
      end
    end

    context "when the activity is authorised" do
      let(:csv_row) { valid_csv_row(actual: "10000", refund: "0", comment: "") }

      it "returns the new record with no errors" do
        allow(ActivityPolicy).to receive(:new).and_return(authorised_policy)

        allow(activity).to receive(:roda_identifier).and_return("VALID-RODA-IDENTIFIER")
        allow(activity).to receive(:organisation).and_return(organisation)
        allow(activity).to receive(:associated_fund).and_return(fund)

        allow(report).to receive(:organisation).and_return(organisation)
        allow(report).to receive(:fund).and_return(fund)

        allow(subject).to receive(:find_activity).and_return(activity)
        allow(subject).to receive(:type_of_row).and_return(:comment)
        allow(subject).to receive(:create_activity_comment).and_return(Result.new(true, valid_comment))

        result = subject.import!
        errors = subject.errors

        expect(result).to be valid_comment
        expect(errors.count).to be_zero
      end
    end

    context "when the activity is not authorised" do
      let(:csv_row) { valid_csv_row(actual: "10000", refund: "0", comment: "") }

      context "because the user cannot create" do
        it "returns false with an error" do
          allow(ActivityPolicy).to receive(:new).and_return(unauthorised_policy)

          allow(activity).to receive(:roda_identifier).and_return("VALID-RODA-IDENTIFIER")

          allow(subject).to receive(:find_activity).and_return(activity)

          result = subject.import!
          errors = subject.errors

          expect(result).to be false

          expect(errors.count).to be 1
          expect(error_for_attribute(errors, "Activity RODA Identifier").value).to eql "VALID-RODA-IDENTIFIER"
          expect(error_for_attribute(errors, "Activity RODA Identifier").message).to eql "Not authorised"
        end
      end

      context "when the activity is not reportable" do
        let(:csv_row) { valid_csv_row(actual: "10000", refund: "0", comment: "") }

        it "returns false with an error" do
          allow(ActivityPolicy).to receive(:new).and_return(authorised_policy)

          allow(activity).to receive(:roda_identifier).and_return("VALID-RODA-IDENTIFIER")

          allow(subject).to receive(:reportable_activity?).and_return(false)
          allow(subject).to receive(:find_activity).and_return(activity)

          result = subject.import!
          errors = subject.errors

          expect(result).to be false
          expect(errors.count).to be 1
          expect(error_for_attribute(errors, "Activity RODA Identifier").value).to eql "VALID-RODA-IDENTIFIER"
          expect(error_for_attribute(errors, "Activity RODA Identifier").message).to eql "Cannot be included in this report"
        end
      end
    end
  end

  def error_for_attribute(errors, attribute)
    value = errors[attribute][0]
    message = errors[attribute][1]

    OpenStruct.new(attribute: attribute, value: value, message: message)
  end
end
