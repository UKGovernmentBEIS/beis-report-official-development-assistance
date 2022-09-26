# frozen_string_literal: true

class Staff::LevelB::Activities::UploadsController < Staff::BaseController
  include Secured
  include StreamCsvDownload

  def new
    authorize organisation, :bulk_upload?

    @organisation_presenter = OrganisationPresenter.new(organisation)
  end

  def show
    authorize organisation, :bulk_upload?

    @organisation_presenter = OrganisationPresenter.new(organisation)
    filename = @organisation_presenter.filename_for_activities_template

    stream_csv_download(filename: filename, headers: csv_headers)
  end

  def update
    authorize organisation, :bulk_upload?

    @organisation_presenter = OrganisationPresenter.new(organisation)
    upload = CsvFileUpload.new(params[:organisation], :activity_csv)
    @success = false

    if upload.valid?
      importer = ::Activities::ImportFromCsv.new(
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
    ["RODA ID"] + ::Activities::ImportFromCsv.level_b_column_headings
  end

  def organisation
    @organisation ||= Organisation.find(params[:organisation_id])
  end
end
