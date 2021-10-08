RSpec.describe Import::Commitments do
  before(:all) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start

    @activity = create(:project_activity, roda_identifier: "RODA-ID")
    @commitment = create(:commitment, activity_id: @activity.id, value: 500_000_00)
    create(:project_activity, roda_identifier: "RODA-ID-1")
    create(:project_activity, roda_identifier: "RODA-ID-2")
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  subject { described_class.new }

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
  end

  context "with a file that has valid headers" do
    context "when all rows are valid" do
      let(:valid_csv) { load_csv_fixture("valid.csv") }

      it "creates a new Commitment and updates an existing one" do
        expect { subject.call(valid_csv) }.to change { Commitment.count }.by(1)
        expect(@commitment.reload.value).to eq 100.00
        expect(Commitment.count).to eq 2
      end

      it "returns true" do
        expect(subject.call(valid_csv)).to eq true
      end

      it "returns the imported items" do
        subject.call(valid_csv)
        expect(subject.imported.count).to eq 2
      end

      it "retunrs no errors" do
        subject.call(valid_csv)
        expect(subject.errors.count).to eq 0
      end
    end
  end

  describe Import::Commitments::RowImporter do
    context "with a valid set of attributes in the row" do
      let(:row) { CSV::Row.new(["RODA identifier", "Commitment value"], ["RODA-ID", 3000]) }
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
      let(:row) { CSV::Row.new(["RODA identifier", "Commitment value"], ["NOT_A_RODA_ID", 3_000]) }
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
      let(:row) { CSV::Row.new(["RODA identifier", "Commitment value"], ["RODA-ID", -10_000]) }
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

    context "with a value outside the allowed range in the row" do
      let(:row) { CSV::Row.new(["RODA identifier", "Commitment value"], ["RODA-ID", 100_000_000_000]) }
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
