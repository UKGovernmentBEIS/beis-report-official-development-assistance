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
end
