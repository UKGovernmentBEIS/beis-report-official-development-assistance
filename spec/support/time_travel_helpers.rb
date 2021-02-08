module TimeTravelHelpers
  def travel_to_quarter(quarter, year, &block)
    date = FinancialQuarter.new(year.to_i, quarter.to_i).start_date

    travel_to(date, &block)
  end
end
