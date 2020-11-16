class ReportingCycle
  def initialize(activity, financial_quarter, financial_year)
    @activity = activity
    @financial_quarter = financial_quarter
    @financial_year = financial_year
  end

  def tick
    create_report
  end

  private

  def create_report
    @report = Report.new(fund: @activity.associated_fund, organisation: @activity.organisation)

    @report.financial_quarter = @financial_quarter
    @report.financial_year = @financial_year
    @report.state = :active

    @report.save!
  end
end
