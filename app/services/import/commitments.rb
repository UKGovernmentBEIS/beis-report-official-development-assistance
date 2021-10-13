class Import::Commitments
  class RowError < StandardError
    attr_reader :row_number

    def initialize(message, row_number)
      @row_number = row_number
      super(message)
    end
  end

  VALID_HEADERS = [
    "RODA identifier",
    "Commitment value",
    "Financial quarter",
    "Financial year",
  ]

  attr_reader :errors, :imported, :user

  def initialize(user)
    @errors = []
    @imported = []
    @user = user
  end

  def call(csv)
    import_rows_from_csv(csv)
  end

  private

  def import_rows_from_csv(csv)
    return false unless includes_valid_headers?(csv.headers)

    ActiveRecord::Base.transaction do
      csv.each.with_index(2) do |row, row_number|
        row_importer = RowImporter.new(row_number, row)

        if row_importer.call
          @imported.append(row_importer.commitment)
        else
          @errors.concat(row_importer.errors)
        end
      end

      if @errors.any?
        raise ActiveRecord::Rollback
      end
    end

    return false if @errors.any?

    record_history
    true
  end

  def record_history
    imported.each do |commitment|
      changes = {
        value: [nil, commitment.value],
      }
      HistoryRecorder.new(user: user).call(
        changes: changes,
        reference: "Commitment imported",
        activity: commitment.activity,
        trackable: commitment,
        report: nil
      )
    end
  end

  def includes_valid_headers?(headers)
    if headers & VALID_HEADERS == VALID_HEADERS
      true
    else
      @errors << RowError.new("No valid headers, must include #{VALID_HEADERS.to_sentence}", 1)
      false
    end
  end

  class RowImporter
    attr_reader :errors, :commitment, :row_number, :row

    def initialize(row_number, row)
      @row_number = row_number
      @row = row
      @errors = []
      @commitment = nil
    end

    def call
      if activity_id.nil?
        @errors << RowError.new("Unknown RODA identifier #{roda_identifier}", row_number)
        return false
      end

      if activities_with_commitments.include?(activity_id)
        @errors << RowError.new("Activiy with RODA identifier #{roda_identifier} already has a commitment set.", row_number)
        return false
      end

      set_commitment
    end

    private

    def activity_id
      roda_identifier_to_activity_id
    end

    def roda_identifier
      @row.field("RODA identifier")
    end

    def value
      @row.field("Commitment value")
    end

    def financial_quarter
      @row.field("Financial quarter")
    end

    def financial_year
      @row.field("Financial year")
    end

    def set_commitment
      commitment = Commitment.new(
        activity_id: activity_id,
        value: value,
        financial_quarter: financial_quarter,
        financial_year: financial_year
      )
      if commitment.valid?
        commitment.save
        @commitment = commitment
        true
      else
        @errors = active_model_to_import_errors_for_row(commitment.errors)
        false
      end
    end

    def roda_identifier_to_activity_id
      return if roda_identifier.nil?
      activity_ids_and_roda_identifiers.fetch(roda_identifier, nil)
    end

    def active_model_to_import_errors_for_row(errors)
      errors.map { |error| RowError.new(error.message, row_number) }
    end

    def activity_ids_and_roda_identifiers
      @_activity_ids_and_roda_identifiers ||= Activity.all.pluck(:roda_identifier, :id).to_h
    end

    def activities_with_commitments
      @_activity_with_commitments ||= Commitment.all.pluck(:activity_id)
    end
  end
end
