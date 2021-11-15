class Staff::Uploads::ActualHistoriesController < Staff::BaseController
  include Reports::Breadcrumbed

  def new
    @report = Report.find(params[:report_id])
    authorize @report, :upload_history?

    prepare_default_report_trail(@report)
    add_breadcrumb t("breadcrumb.uploads.actual_histories"), new_report_uploads_actual_history_path(@report)
  end
end
