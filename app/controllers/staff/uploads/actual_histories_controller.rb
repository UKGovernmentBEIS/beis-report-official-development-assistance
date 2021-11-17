class Staff::Uploads::ActualHistoriesController < Staff::BaseController
  include Reports::Breadcrumbed

  def new
    @report = Report.find(params[:report_id])
    authorize @report, :upload_history?

    set_breadcrumb
  end

  def update
    @report = Report.find(params[:report_id])
    authorize @report, :upload_history?

    set_breadcrumb

    return handle_missing_file unless file_supplied?

    upload = CsvFileUpload.new(params[:report], :actual_csv_file)

    return handle_invalid_file unless upload.valid?

    importer = Import::ActualHistory.new(report: @report, csv: upload.rows, user: current_user)
    @errors = importer.errors
    @imported_actuals = importer.imported

    if importer.imported?
      render_uploaded_actual_history
    else
      render_uploaded_actual_history_errors
    end
  end

  private

  def render_uploaded_actual_history
    @total_actuals = TotalPresenter.new(@imported_actuals.sum(&:value)).value

    @grouped_actuals = @imported_actuals
      .map { |actual| TransactionPresenter.new(actual) }
      .group_by { |actual| ActivityPresenter.new(actual.parent_activity) }

    flash[:notice] = t("actions.uploads.actual_histories.success")
    render :update
  end

  def render_uploaded_actual_history_errors
    flash[:error] = t("actions.uploads.actual_histories.failed")
    render :update
  end

  def handle_missing_file
    flash[:error] = t("actions.uploads.actual_histories.missing")
    render :new
  end

  def handle_invalid_file
    flash[:error] = t("actions.uploads.actual_histories.invalid")
    render :new
  end

  def file_supplied?
    params.dig(:report, :actual_csv_file).present?
  end

  def set_breadcrumb
    prepare_default_report_trail(@report)
    add_breadcrumb t("breadcrumb.uploads.actual_histories"), new_report_uploads_actual_history_path(@report)
  end
end
