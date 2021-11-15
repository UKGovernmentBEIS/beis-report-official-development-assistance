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

    upload = CsvFileUpload.new(params[:report], :actual_csv_file)

    if upload.valid?
      flash.now[:notice] = t("actions.uploads.actual_histories.success")
    else
      flash.now[:error] = t("actions.uploads.actual_histories.missing_or_invalid")
    end
    render :new
  end

  private

  def set_breadcrumb
    prepare_default_report_trail(@report)
    add_breadcrumb t("breadcrumb.uploads.actual_histories"), new_report_uploads_actual_history_path(@report)
  end
end
