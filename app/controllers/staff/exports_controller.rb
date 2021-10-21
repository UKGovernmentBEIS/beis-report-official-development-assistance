class Staff::ExportsController < Staff::BaseController
  include Secured
  include StreamCsvDownload

  def index
    authorize :export, :index?

    add_breadcrumb t("breadcrumbs.export.index"), :exports_path

    @organisations = policy_scope(Organisation).delivery_partner
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
    fund = Fund.new(params[:fund_id])

    respond_to do |format|
      format.csv do
        export = Export::SpendingBreakdown.new(source_fund: fund)

        stream_csv_download(filename: export.filename, headers: export.headers) do |csv|
          export.rows.each { |row| csv << row }
        end
      end
    end
  end
end
