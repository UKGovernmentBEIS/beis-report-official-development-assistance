class ReportingCycle
  def initialize(activity, financial_quarter, financial_year)
    @activity = activity
    @financial_quarter = financial_quarter
    @financial_year = financial_year
    @report = nil
  end

  def tick
    approve_report
    create_report
    increment_quarter
  end

  private

  def approve_report
    @report&.update!(state: :approved)
  end

  def create_report
    @report = Report.new(fund: @activity.associated_fund, organisation: @activity.organisation)

    @report.created_at = FinancialPeriod.start_date_from_quarter_and_year(@financial_quarter.to_s, @financial_year.to_s)
    @report.financial_quarter = @financial_quarter
    @report.financial_year = @financial_year
    @report.state = :active

    @report.save!
  end

  def increment_quarter
    @financial_quarter += 1

    if @financial_quarter > 4
      @financial_year += 1
      @financial_quarter = 1
    end
  end
end
