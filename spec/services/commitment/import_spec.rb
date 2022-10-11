RSpec.describe Commitment::Import do
  before(:all) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start

    @activity = create(:project_activity, roda_identifier: "RODA-ID")
    @user = create(:beis_user)
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  subject { described_class.new(@user) }

  context "with a file that does not have valid headers" do
    let(:invalid_headers_csv) { load_csv_fixture("invalid_headers.csv") }

    it "stops and returns false" do
      expect(subject.call(invalid_headers_csv)).to eq false
    end

    it "returns a helpful error message" do
      subject.call(invalid_headers_csv)
      expect(subject.errors.count).to eq 1

      row_one_error = subject.errors.first
      expect(row_one_error.message).to include("No valid headers")
      expect(row_one_error.row_number).to eq 1
    end

    it "does not create or update any Commitments" do
      expect { subject.call(invalid_headers_csv) }.not_to change { Commitment.count }
    end

    it "returns no imported items" do
      subject.call(invalid_headers_csv)
      expect(subject.imported).to eq []
    end

    it "does not an record historical event" do
      expect { subject.call(invalid_headers_csv) }.not_to change { HistoricalEvent.count }
    end
  end

  context "with a file that has valid headers" do
    context "when all rows are valid" do
      let(:valid_csv) { load_csv_fixture("valid.csv") }

      it "sets the commitment on an acitivity that has none" do
        expect { subject.call(valid_csv) }.to change { Commitment.count }.by(1)
      end

      it "sets the commitment value" do
        subject.call(valid_csv)
        expect(subject.imported.first.value).to eq 200
      end

      it "returns true" do
        expect(subject.call(valid_csv)).to eq true
      end

      it "returns the imported items" do
        subject.call(valid_csv)
        expect(subject.imported.count).to eq 1
      end

      it "returns no errors" do
        subject.call(valid_csv)
        expect(subject.errors.count).to eq 0
      end

      it "records a event in the history" do
        expect { subject.call(valid_csv) }.to change { HistoricalEvent.count }.by(1)
        historical_event = HistoricalEvent.first

        expect(historical_event.new_value).to eql 200
        expect(historical_event.previous_value).to be_nil
        expect(historical_event.reference).to eq "Commitment imported"
        expect(historical_event.user).to eq @user
      end
    end

    context "when there are errors" do
      let(:invalid_csv) { load_csv_fixture("invalid.csv") }

      it "does not set the commitment" do
        expect { subject.call(invalid_csv) }.not_to change { Commitment.count }
      end

      it "returns false" do
        expect(subject.call(invalid_csv)).to eq false
      end

      it "returns no imported items" do
        subject.call(invalid_csv)
        expect(subject.imported.count).to eq 0
      end

      it "includes them in the list of errors" do
        invalid_errors = [
          Commitment::Import::RowError.new("Value must be greater than 0", 2),
          Commitment::Import::RowError.new("Financial year can't be blank", 2),
          Commitment::Import::RowError.new("Financial year is not a number", 2)
        ]
        unknown_error = Commitment::Import::RowError.new("Unknown RODA identifier UNKNOWN-RODA-ID", 3)
        subject.call(invalid_csv)

        expect(subject.errors.count).to eq 4
        expect(subject.errors).to include(invalid_errors.first)
        expect(subject.errors).to include(invalid_errors.second)
        expect(subject.errors).to include(invalid_errors.third)
        expect(subject.errors).to include(unknown_error)
      end

      it "does not record an event in the history" do
        expect { subject.call(invalid_csv) }.not_to change { HistoricalEvent.count }
      end
    end
  end

  describe Commitment::Import::RowImporter do
    context "with a valid set of attributes in the row" do
      let(:row) {
        CSV::Row.new(
          ["RODA identifier", "Commitment value", "Financial quarter", "Financial year"],
          ["RODA-ID", 3000, 1, 2021]
        )
      }

      subject { described_class.new(1, row) }

      it "returns true" do
        expect(subject.call).to eq true
      end

      it "retruns the commitment" do
        subject.call
        expect(subject.commitment.value).to eq 3000
        expect(subject.commitment.activity_id).to eq @activity.id
      end

      it "returns no errors" do
        subject.call
        expect(subject.errors.count).to eq 0
      end
    end

    context "with an unknown RODA ID in the row" do
      let(:row) {
        CSV::Row.new(
          ["RODA identifier", "Commitment value", "Financial quarter", "Financial year"],
          ["NOT_A_RODA_ID", 3_000, 1, 2021]
        )
      }
      subject { described_class.new(100, row) }

      it "returns false" do
        expect(subject.call).to eq false
      end

      it "returns a helpful error message" do
        subject.call
        expect(subject.errors.count).to eq 1
        expect(subject.errors.first.message).to include("Unknown RODA identifier")
        expect(subject.errors.first.row_number).to eq 100
      end

      it "does not include the commitment" do
        subject.call
        expect(subject.commitment).to be_nil
      end
    end

    context "with a negative value in the row" do
      let(:row) {
        CSV::Row.new(
          ["RODA identifier", "Commitment value", "Financial quarter", "Financial year"],
          ["RODA-ID", -1_000, 1, 2021]
        )
      }
      subject { described_class.new(10, row) }

      it "returns false" do
        expect(subject.call).to eq false
      end

      it "returns a helpful error message" do
        subject.call
        expect(subject.errors.count).to eq 1
        expect(subject.errors.first.message).to include("greater than 0")
        expect(subject.errors.first.row_number).to eq 10
      end

      it "does not include the commitment" do
        subject.call
        expect(subject.commitment).to be_nil
      end
    end

    context "when the acitivty already has a commitment" do
      let!(:commitment) { create(:commitment, activity_id: @activity.id) }
      let(:row) {
        CSV::Row.new(
          ["RODA identifier", "Commitment value", "Financial quarter", "Financial year"],
          ["RODA-ID", 100_000, 1, 2021]
        )
      }
      subject { described_class.new(11, row) }

      it "returns false" do
        expect(subject.call).to eq false
      end

      it "returns a helpful error message" do
        subject.call
        expect(subject.errors.count).to eq 1
        expect(subject.errors.first.message).to include("already has a commitment set")
        expect(subject.errors.first.row_number).to eq 11
      end

      it "does not include the commitment" do
        subject.call
        expect(subject.commitment).to be_nil
      end
    end

    context "with a value outside the allowed range in the row" do
      let(:row) {
        CSV::Row.new(
          ["RODA identifier", "Commitment value", "Financial quarter", "Financial year"],
          ["RODA-ID", 100_000_000_000, 1, 2021]
        )
      }
      subject { described_class.new(1, row) }

      it "returns false" do
        expect(subject.call).to eq false
      end

      it "returns a helpful error message" do
        subject.call
        expect(subject.errors.count).to eq 1
        expect(subject.errors.first.message).to include("Value must be less than or equal to")
        expect(subject.errors.first.row_number).to eq 1
      end

      it "does not include the commitment" do
        subject.call
        expect(subject.commitment).to be_nil
      end
    end
  end

  def load_csv_fixture(csv_file_path)
    CSV.read("spec/fixtures/csv/commitments/#{csv_file_path}", {headers: true, encoding: "bom|utf-8"})
  end
end
