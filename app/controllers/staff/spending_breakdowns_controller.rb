class Staff::SpendingBreakdownsController < Staff::BaseController
  include Secured
  include StreamCsvDownload

  def show
    @report = Report.find(params[:report_id])
    authorize @report

    @report_presenter = ReportPresenter.new(@report)
    @report_activities = Activity::ProjectsForReportFinder.new(report: @report)

    respond_to do |format|
      format.csv { send_csv }
    end
  end

  private

  def send_csv
    filename = @report_presenter.filename_for_report_download
    headers = ActivitySpendingBreakdown.new(report: @report).headers

    stream_csv_download(filename: filename, headers: headers) do |csv|
      @report_activities.each do |activity|
        breakdown = ActivitySpendingBreakdown.new(report: @report, activity: activity)
        csv << breakdown.values
      end
    end
  end
end
