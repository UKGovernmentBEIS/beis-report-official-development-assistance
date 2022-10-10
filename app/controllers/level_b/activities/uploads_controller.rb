# frozen_string_literal: true

class LevelB::Activities::UploadsController < BaseController
  include Secured
  include StreamCsvDownload

  def new
    authorize :level_b, :activity_upload?

    @organisation_presenter = OrganisationPresenter.new(organisation)
  end

  def show
    authorize :level_b, :activity_upload?

    @organisation_presenter = OrganisationPresenter.new(organisation)
    filename = @organisation_presenter.filename_for_activities_template

    stream_csv_download(filename: filename, headers: csv_headers)
  end

  def update
    authorize :level_b, :activity_upload?

    @organisation_presenter = OrganisationPresenter.new(organisation)
    upload = CsvFileUpload.new(params[:organisation], :activity_csv)
    @success = false

    if upload.valid?
      importer = Activity::Import.new(
        uploader: current_user,
        partner_organisation: organisation,
        report: nil
      )
      importer.import(upload.rows)
      @errors = importer.errors
      @activities = {created: importer.created, updated: importer.updated}

      if @errors.empty?
        @success = true
        flash.now[:notice] = t("action.activity.upload.success")
      end
    else
      @errors = []
      flash.now[:error] = t("action.activity.upload.file_missing_or_invalid")
    end
  end

  private

  def csv_headers
    ["RODA ID"] + Activity::Import.level_b_column_headings
  end

  def organisation
    @organisation ||= Organisation.find(params[:organisation_id])
  end
end
