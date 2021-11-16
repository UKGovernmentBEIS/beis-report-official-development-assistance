RSpec.describe Import::ActualHistory do
  before(:all) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start

    @activity = create(:project_activity)
    @report = create(
      :report,
      organisation: @activity.organisation,
      fund: @activity.associated_fund
    )
    @user = create(:beis_user)

    valid_data = <<~CSV
      RODA identifier,Financial quarter,Financial year,Value
      #{@activity.roda_identifier},1,2021,10000
      #{@activity.roda_identifier},2,2021,20000
      #{@activity.roda_identifier},3,2021,30000
    CSV

    invalid_data = <<~CSV
      RODA identifier,Financial quarter,Financial year,Value
      NOT-A-RODA-ID,1,2021,10000
      #{@activity.roda_identifier},Quarter 1,2021,10000
      #{@activity.roda_identifier},1,the year of 2021,10000
      #{@activity.roda_identifier},1,2021,0
      #{@activity.roda_identifier},1,2021,10000
    CSV

    invalid_headers = <<~CSV
      Not,Valid,Headers
    CSV

    @valid_csv = CSV.parse(valid_data, headers: true)
    @invalid_csv = CSV.parse(invalid_data, headers: true)
    @invalid_headers_csv = CSV.parse(invalid_headers, headers: true)
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  context "with valid data" do
    subject { described_class.new(report: @report, csv: @valid_csv) }

    it "returns true" do
      expect(subject.call).to be true
    end

    it "creates the actuals" do
      expect { subject.call }.to change { Actual.count }.by(3)
    end

    it "returns the imported actuals" do
      subject.call
      expect(subject.imported.count).to eq 3
    end
  end

  context "with invalid headers" do
    subject { described_class.new(report: @report, csv: @invalid_headers_csv) }

    it "returns false" do
      expect(subject.call).to be false
    end

    it "returns the correct number of errors" do
      subject.call
      expect(subject.errors.count).to eq 1
    end

    it "returns the errros" do
      subject.call
      expect(subject.errors.first.message).to include "Invalid headers,"
    end

    it "does not create any actuals" do
      expect { subject.call }.not_to change { Actual.count }
    end
  end

  context "with invalid data" do
    subject { described_class.new(report: @report, csv: @invalid_csv) }

    it "returns false" do
      expect(subject.call).to be false
    end

    it "returns all of the errors" do
      subject.call
      expect(subject.errors.count).to eq 4
    end

    describe "the errors" do
      it "returns the error for the first row" do
        subject.call
        error = subject.errors.first
        expect(error.row_number).to eq 2
        expect(error.message).to include("RODA identifier")
      end

      it "returns the error for the second row" do
        subject.call
        error = subject.errors.second
        expect(error.row_number).to eq 3
        expect(error.message).to include("Enter a financial quarter between 1 and 4")
      end

      it "returns the error for the third row" do
        subject.call
        error = subject.errors.third
        expect(error.row_number).to eq 4
        expect(error.message).to include("Date must be between")
      end

      it "returns the error for the fourth row" do
        subject.call
        error = subject.errors.fourth
        expect(error.row_number).to eq 5
        expect(error.message).to include("Value must not be zero")
      end
    end
  end

  describe Import::ActualHistory::RowImport do
    context "with valid row data" do
      let(:row) {
        CSV::Row.new(
          ["RODA identifier", "Financial quarter", "Financial year", "Value"],
          [@activity.roda_identifier, "1", "2021", "10000"]
        )
      }

      subject { described_class.new(report: @report, row_number: 2, row: row) }

      it "returns true" do
        expect(subject.call).to be true
      end

      it "returns no errors" do
        subject.call
        expect(subject.errors.count).to eq 0
      end

      it "creates the actual" do
        expect { subject.call }.to change { Actual.count }.by(1)
      end

      describe "the new actual" do
        subject { described_class.new(report: @report, row_number: 2, row: row) }

        it "has the correct parent activity" do
          subject.call
          expect(subject.actual.parent_activity).to eq @activity
        end

        it "has the correct financial quarter" do
          subject.call
          expect(subject.actual.financial_quarter).to eq 1
        end
        it "has the correct financial year" do
          subject.call
          expect(subject.actual.financial_year).to eq 2021
        end

        it "has the correct value" do
          subject.call
          expect(subject.actual.value).to eq BigDecimal(10_000)
        end

        it "has the correct report" do
          subject.call
          expect(subject.actual.report).to eq @report
        end

        it "validates the actual in the history context" do
          actual = double(Actual, valid?: true, save: true)
          allow(Actual).to receive(:new).and_return(actual)

          subject.call

          expect(actual).to have_received(:valid?).with(:history)
        end

        it "saves the actual in the history context" do
          actual = double(Actual, valid?: true, save: true)
          allow(Actual).to receive(:new).and_return(actual)

          subject.call

          expect(actual).to have_received(:save).with(context: :history)
        end
      end
    end

    context "with invalid row data" do
      let(:row) {
        CSV::Row.new(
          ["RODA identifier", "Financial quarter", "Financial year", "Value"],
          ["NOT-A-RODA-ID", "Quarter One", "the year 2021", "0"]
        )
      }

      subject { described_class.new(report: @report, row_number: 2, row: row) }

      it "returns false" do
        expect(subject.call).to be false
      end

      it "returns errors" do
        subject.call
        expect(subject.errors.count).to eq 1
      end

      it "does not create the actual" do
        expect(subject.actual).to be_nil
      end

      it "has a helpful error message" do
        subject.call
        expect(subject.errors.first.message).to include("Unknown RODA identifier")
      end
    end

    context "when the row data has and incorrect but valid activity" do
      let(:other_activity) { create(:project_activity) }
      let(:row) {
        CSV::Row.new(
          ["RODA identifier", "Financial quarter", "Financial year", "Value"],
          [other_activity.roda_identifier, "1", "2021", "100000"]
        )
      }

      subject { described_class.new(report: @report, row_number: 2, row: row) }

      it "returns false" do
        expect(subject.call).to be false
      end

      it "returns errors" do
        subject.call
        expect(subject.errors.count).to eq 1
      end

      it "does not create the actual" do
        expect(subject.actual).to be_nil
      end

      it "has a helpful error message" do
        subject.call
        expect(subject.errors.first.message)
          .to include("does not match the fund and organisation of this report")
      end
    end
  end
end
