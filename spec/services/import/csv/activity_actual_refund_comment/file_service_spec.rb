require "rails_helper"

RSpec.describe Import::Csv::ActivityActualRefundComment::FileService, type: :import_csv do
  let(:report) { create(:report) }
  let(:user) { create(:partner_organisation_user) }
  let(:activity) { create(:project_activity) }
  let(:csv) { CSV::Table.new(rows, headers: headers) }

  subject { described_class.new(report: report, user: user, csv_rows: csv) }

  describe "#import!" do
    context "when the supplied data does not include the required column headers" do
      let(:headers) { ["Not a valid header", "And neither is this"] }
      let(:rows) { [] }

      it "returns false" do
        result = subject.import!

        expect(result).to be false
      end
    end

    context "when the supplied data contains the required headers" do
      let(:headers) { ["Activity RODA Identifier", "Financial Quarter", "Financial Year", "Actual Value", "Refund Value", "Comment"] }

      context "and the data contains an actual" do
        let(:rows) { [CSV::Row.new(headers, ["RODA-ID", "2", "2023", "10000", "0", ""])] }

        before do
          allow(Activity).to receive(:find_by_roda_identifier).with("RODA-ID").and_return(activity)
          allow_any_instance_of(Import::Csv::ActivityActualRefundComment::RowService).to receive(:authorise_activity).and_return(true)
        end

        it "creates the Actual and returns true" do
          result = subject.import!
          actual = subject.imported_rows.first.object

          expect(actual.parent_activity).to be activity
          expect(actual.value).to eql BigDecimal("10000")
          expect(actual.financial_quarter).to be 2
          expect(actual.financial_year).to be 2023
          expect(actual.comment).to be_nil

          expect(result).to be true
        end

        it "populates the imported rows" do
          subject.import!

          expect(subject.imported_rows.count).to be 1
          expect(subject.imported_actuals.count).to be 1
          expect(subject.imported_refunds.count).to be_zero
          expect(subject.imported_comments.count).to be_zero
          expect(subject.skipped_rows.count).to be_zero
        end

        it "produces no errors" do
          subject.import!
          errors = subject.errors

          expect(errors.count).to be_zero
        end
      end

      context "and the data contains an refund" do
        let(:rows) { [CSV::Row.new(headers, ["RODA-ID", "2", "2023", "0", "20000", "This is a refund comment."])] }

        before do
          allow(Activity).to receive(:find_by_roda_identifier).with("RODA-ID").and_return(activity)
          allow_any_instance_of(Import::Csv::ActivityActualRefundComment::RowService).to receive(:authorise_activity).and_return(true)
          allow(Report).to receive(:editable_for_activity).with(activity).and_return(report)
        end

        it "creates the Refund and returns true" do
          result = subject.import!
          refund = subject.imported_rows.first.object

          expect(refund.parent_activity).to eql activity
          expect(refund.comment.body).to eql "This is a refund comment."
          expect(refund.value).to eql BigDecimal("-20000")
          expect(refund.financial_quarter).to eql 2
          expect(refund.financial_year).to eql 2023

          expect(result).to be true
        end

        it "populates the imported rows" do
          subject.import!

          expect(subject.imported_rows.count).to be 1
          expect(subject.imported_actuals.count).to be_zero
          expect(subject.imported_refunds.count).to be 1
          expect(subject.imported_comments.count).to be_zero
          expect(subject.skipped_rows.count).to be_zero
        end

        it "produces no errors" do
          subject.import!
          errors = subject.errors

          expect(errors.count).to be_zero
        end
      end

      context "and the data contains an activity comment" do
        let(:rows) { [CSV::Row.new(headers, ["RODA-ID", "2", "2023", "0", "0", "This is an activity comment."])] }

        before do
          allow(Activity).to receive(:find_by_roda_identifier).with("RODA-ID").and_return(activity)
          allow_any_instance_of(Import::Csv::ActivityActualRefundComment::RowService).to receive(:authorise_activity).and_return(true)
        end

        it "creates the Comment and returns true" do
          result = subject.import!
          imported_comment = subject.imported_rows.first.object

          expect(result).to be true

          expect(imported_comment.commentable).to eql activity
          expect(imported_comment.body).to eql "This is an activity comment."
        end

        it "populates the imported rows" do
          subject.import!

          expect(subject.imported_rows.count).to be 1
          expect(subject.imported_actuals.count).to be_zero
          expect(subject.imported_refunds.count).to be_zero
          expect(subject.imported_comments.count).to be 1
          expect(subject.skipped_rows.count).to be_zero
        end

        it "produces no errors" do
          errors = subject.errors

          expect(errors.count).to be_zero
        end
      end

      context "and the data contains an empty row" do
        let(:rows) { [CSV::Row.new(headers, ["RODA-ID", "2", "2023", "0", "0", ""])] }

        before do
          allow(Activity).to receive(:find_by_roda_identifier).with("RODA-ID").and_return(activity)
          allow_any_instance_of(Import::Csv::ActivityActualRefundComment::RowService).to receive(:authorise_activity).and_return(true)
        end

        it "populates the imported rows" do
          subject.import!

          expect(subject.imported_rows.count).to be 1
          expect(subject.imported_actuals.count).to be_zero
          expect(subject.imported_refunds.count).to be_zero
          expect(subject.imported_comments.count).to be_zero
          expect(subject.skipped_rows.count).to be 1
        end

        it "records the details of the skipped row" do
          subject.import!
          skipped = subject.skipped_rows.first.object

          expect(skipped.roda_identifier).to eql "RODA-ID"
          expect(skipped.financial_quarter).to eql "2"
          expect(skipped.financial_year).to eql "2023"
        end

        it "produces no errors" do
          subject.import!
          errors = subject.errors

          expect(errors.count).to be_zero
        end
      end

      context "and the data has all the types" do
        let(:actual_row) { CSV::Row.new(headers, ["RODA-ID", "2", "2023", "10000", "0", ""]) }
        let(:refund_row) { CSV::Row.new(headers, ["RODA-ID", "2", "2023", "0", "200000", "This is a refund comment."]) }
        let(:comment_row) { CSV::Row.new(headers, ["RODA-ID", "2", "2023", "0", "0", "This is an activity comment."]) }
        let(:empty_row) { CSV::Row.new(headers, ["RODA-ID", "2", "2023", "0", "0", ""]) }

        let(:rows) { [actual_row, refund_row, comment_row, empty_row] }

        before do
          allow(Activity).to receive(:find_by_roda_identifier).with("RODA-ID").and_return(activity)
          allow_any_instance_of(Import::Csv::ActivityActualRefundComment::RowService).to receive(:authorise_activity).and_return(true)
          allow(Report).to receive(:editable_for_activity).with(activity).and_return(report)
        end

        it "populates the imported rows" do
          result = subject.import!

          expect(result).to be true
          expect(subject.imported_rows.count).to be 4
          expect(subject.imported_actuals.count).to be 1
          expect(subject.imported_refunds.count).to be 1
          expect(subject.imported_comments.count).to be 1
          expect(subject.skipped_rows.count).to be 1
        end

        it "produces no errors" do
          subject.import!
          errors = subject.errors

          expect(errors.count).to be_zero
        end
      end

      context "when there are errors" do
        context "when there is only one row" do
          context "when required values are missing" do
            let(:rows) { [CSV::Row.new(headers, ["", "2", "2023", "10000", "0", ""])] }

            it "returns false with the error and imported rows is empty" do
              result = subject.import!
              errors = subject.errors

              expect(result).to be false

              expect(errors.count).to be 1
              expect(errors.first.column).to eql "Activity RODA Identifier"
              expect(errors.first.message).to eql "Is required"

              expect(subject.imported_rows.count).to be_zero
            end
          end

          context "when the row data is invalid" do
            let(:rows) { [CSV::Row.new(headers, ["RODA-ID", "2", "2023", "ten thousand pounds", "0", ""])] }

            it "returns false with the error and imported rows is empty" do
              result = subject.import!
              errors = subject.errors

              expect(result).to be false

              expect(errors.count).to be 1
              expect(errors.first.column).to eql "Actual Value"
              expect(errors.first.message).to eql "Must be a financial value"

              expect(subject.imported_rows.count).to be_zero
            end
          end

          context "when the objects cannot be saved" do
            let(:rows) { [CSV::Row.new(headers, ["RODA-ID", "2", "2023", "10000", "0", ""])] }
            let(:invalid_actual) { double(Actual, errors: [double(attribute: "value", message: "Value must not be zero")], save!: false) }

            before do
              allow(Activity).to receive(:find_by_roda_identifier).with("RODA-ID").and_return(activity)
              allow_any_instance_of(Import::Csv::ActivityActualRefundComment::RowService).to receive(:authorise_activity).and_return(true)
              allow_any_instance_of(CreateActual).to receive(:call).and_return(Result.new(false, invalid_actual))
            end

            it "returns false with the error and imported rows is empty" do
              result = subject.import!
              errors = subject.errors

              expect(result).to be false

              expect(errors.count).to be 1
              expect(errors.first.column).to eql "value"
              expect(errors.first.message).to eql "Value must not be zero"

              expect(subject.imported_rows.count).to be_zero
            end
          end
        end

        context "when there is more than one row" do
          let(:actual_row) { CSV::Row.new(headers, ["RODA-ID", "2", "2023", "10000", "0", ""]) }
          let(:refund_row) { CSV::Row.new(headers, ["RODA-ID", "2", "2023", "0", "200000", "This is a refund comment."]) }
          let(:comment_row) { CSV::Row.new(headers, ["RODA-ID", "2", "2023", "0", "0", "This is an activity comment."]) }

          context "when at least one row is invalid" do
            let(:invalid_row) { CSV::Row.new(headers, ["RODA-ID", "2", "2023", "ten thousand pounds", "0", ""]) }

            let(:rows) { [actual_row, refund_row, comment_row, invalid_row] }

            before do
              allow(Activity).to receive(:find_by_roda_identifier).with("RODA-ID").and_return(activity)
              allow_any_instance_of(Import::Csv::ActivityActualRefundComment::RowService).to receive(:authorise_activity).and_return(true)
              allow(Report).to receive(:editable_for_activity).with(activity).and_return(report)
            end

            it "returns false and imported rows is empty" do
              result = subject.import!

              expect(result).to be false
              expect(subject.imported_rows.count).to be_zero
            end

            it "creates no database objects" do
              subject.import!

              expect(Actual.count).to be_zero
              expect(Refund.count).to be_zero
              expect(Comment.count).to be_zero
            end
          end
        end
      end
    end
  end
end
