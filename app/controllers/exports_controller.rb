class ExportsController < BaseController
  include Secured
  include StreamCsvDownload

  def index
    authorize :export, :index?

    add_breadcrumb t("breadcrumbs.export.index"), :exports_path

    @organisations = policy_scope(Organisation).partner_organisations
    @funds = Fund.all
  end

  def external_income
    authorize :export, :show_external_income?

    fund = Fund.new(params[:fund_id])

    respond_to do |format|
      format.csv do
        export = ExternalIncome::Export.new(source_fund: fund)

        stream_csv_download(filename: export.filename, headers: export.headers) do |csv|
          export.rows.each { |row| csv << row }
        end
      end
    end
  end

  def budgets
    authorize :export, :show_budgets?

    fund = Fund.new(params[:fund_id])

    respond_to do |format|
      format.csv do
        export = Budget::Export.new(source_fund: fund)

        stream_csv_download(filename: export.filename, headers: export.headers) do |csv|
          export.rows.each { |row| csv << row }
        end
      end
    end
  end

  def spending_breakdown
    authorize :export, :show_external_income?

    add_breadcrumb t("breadcrumbs.export.index"), :exports_path

    SpendingBreakdownJob.perform_later(
      requester_id: current_user.id,
      fund_id: params[:fund_id]
    )

    fund = Fund.new(params[:fund_id])
    email = current_user.email
    @message = "The requested spending breakdown for #{fund.name} is being prepared. " \
               "We will send a download link to #{email} when it is ready."

    render :export_in_progress
  end

  def spending_breakdown_download
    authorize :export, :show_external_income?

    fund = Fund.new(params[:id])
    fund_activity = fund.activity

    spending_breakdown_csv = Export::S3Downloader.new(filename: fund_activity.spending_breakdown_filename).download

    response.headers["Content-Type"] = "text/csv"
    response.headers["Content-Disposition"] = "attachment; filename=#{ERB::Util.url_encode(fund_activity.spending_breakdown_filename)}"
    response.stream.write(spending_breakdown_csv)
    response.stream.close
  end

  def continuing_activities
    authorize :export, :show_continuing_activities?

    respond_to do |format|
      format.csv do
        export = Export::ContinuingActivities.new

        stream_csv_download(filename: export.filename, headers: export.headers) do |csv|
          export.rows.each { |row| csv << row }
        end
      end
    end
  end

  def non_continuing_activities
    authorize :export, :show_continuing_activities?

    respond_to do |format|
      format.csv do
        export = Export::ContinuingActivities.new

        stream_csv_download(filename: export.non_continuing_filename, headers: export.non_continuing_headers) do |csv|
          export.non_continuing_rows.each { |row| csv << row }
        end
      end
    end
  end
end
