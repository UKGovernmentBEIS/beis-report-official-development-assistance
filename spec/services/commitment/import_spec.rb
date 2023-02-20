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
        invalid_error = Commitment::Import::RowError.new("Value must be greater than 0", 2)
        unknown_error = Commitment::Import::RowError.new("Unknown RODA identifier UNKNOWN-RODA-ID", 3)
        subject.call(invalid_csv)

        expect(subject.errors.count).to eq 2
        expect(subject.errors).to include(invalid_error)
        expect(subject.errors).to include(unknown_error)
      end

      it "does not record an event in the history" do
        expect { subject.call(invalid_csv) }.not_to change { HistoricalEvent.count }
      end
    end
  end

  describe Commitment::Import::RowImporter do
    context "with a valid set of attributes in the row" do
      let(:roda_id) { "RODA-ID" }
      let(:row) {
        CSV::Row.new(
          ["RODA identifier", "Commitment value"],
          [roda_id, 3000]
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

      describe "transaction_date" do
        context "when the specified activity has a `planned_start_date`" do
          let(:roda_id) { "RODA-PLANNED-START-DATE-ID" }

          before do
            @activity_with_planned_start_date = create(
              :project_activity,
              roda_identifier: "RODA-PLANNED-START-DATE-ID",
              planned_start_date: "2023-02-20"
            )
          end

          it "returns the planned start date" do
            subject.call
            expect(subject.commitment.transaction_date).to eq(@activity_with_planned_start_date.planned_start_date)
          end
        end

        context "when the specified activity has an `actual_start_date` with no `planned_start_date`" do
          let(:roda_id) { "RODA-ACTUAL-START-DATE-ID" }

          before do
            @activity_with_actual_start_date = create(
              :project_activity,
              roda_identifier: "RODA-ACTUAL-START-DATE-ID",
              planned_start_date: nil,
              actual_start_date: "2023-02-20"
            )
          end

          it "returns the actual start date" do
            subject.call
            expect(subject.commitment.transaction_date).to eq(@activity_with_actual_start_date.actual_start_date)
          end
        end

        context "when the specified activity unexpectedly has neither `actual_start_date` nor `planned_start_date`" do
          let(:roda_id) { "RODA-NO-DATES-ID" }

          before do
            @activity_with_no_dates = build(
              :project_activity,
              roda_identifier: "RODA-NO-DATES-ID",
              planned_start_date: nil,
              actual_start_date: nil
            )
            # Unfortunately, although invalid, we somehow have activities like this in the database
            # so we need to skip validations here to ensure we can handle them
            @activity_with_no_dates.save(validate: false)
          end

          it "returns the date the activity was created" do
            subject.call
            expect(subject.commitment.transaction_date).to eq(@activity_with_no_dates.created_at.to_date)
          end
        end
      end
    end

    context "with an unknown RODA ID in the row" do
      let(:row) {
        CSV::Row.new(
          ["RODA identifier", "Commitment value"],
          ["NOT_A_RODA_ID", 3_000]
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
          ["RODA identifier", "Commitment value"],
          ["RODA-ID", -1_000]
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
          ["RODA identifier", "Commitment value"],
          ["RODA-ID", 100_000]
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
          ["RODA identifier", "Commitment value"],
          ["RODA-ID", 100_000_000_000, 1]
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
    CSV.read("spec/fixtures/csv/commitments/#{csv_file_path}", headers: true, encoding: "bom|utf-8")
  end
end
