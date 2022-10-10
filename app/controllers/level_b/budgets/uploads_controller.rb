# frozen_string_literal: true

class Staff::LevelB::Budgets::UploadsController < Staff::BaseController
  include Secured
  include StreamCsvDownload

  def new
    authorize :level_b, :budget_upload?
  end

  def show
    authorize :level_b, :budget_upload?

    stream_csv_download(filename: "Level_B_budgets_upload.csv", headers: ::Budget::Import::Converter::FIELDS.values)
  end

  def create
    authorize :level_b, :budget_upload?

    upload = CsvFileUpload.new(params[:budget_upload], :csv)
    @success = false

    if upload.valid?
      importer = Budget::Import.new(uploader: current_user)
      importer.import(upload.rows)
      @errors = importer.errors
      @budgets = {created: importer.created}

      if @errors.empty?
        @success = true
        flash.now[:notice] = t("action.budget.upload.success")
      end
    else
      @errors = []
      flash.now[:error] = t("action.budget.upload.file_missing_or_invalid")
    end
  end
end
