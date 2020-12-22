module TimeTravelHelpers
  def travel_to_quarter(quarter, year, &block)
    date = FinancialPeriod.start_date_from_quarter_and_year(quarter.to_s, year.to_s)

    travel_to(date, &block)
  end
end
