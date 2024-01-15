class Import::Csv::ActivityActualRefundComment::SkippedRow
  def initialize(import_row)
    @row = import_row
  end

  def roda_identifier
    @row.roda_identifier
  end

  def financial_quarter
    @row.financial_quarter
  end

  def financial_year
    @row.financial_year
  end
end
