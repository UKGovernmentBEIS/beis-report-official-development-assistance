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
    type = params[:type].to_sym
    filename = @organisation_presenter.filename_for_activities_template(type: type)
    headers = Activity::Import::Field.where_level_and_type(level: :level_b, type: type).map(&:heading)

    stream_csv_download(filename: filename, headers: headers)
  end

  def update
    authorize :level_b, :activity_upload?

    @organisation_presenter = OrganisationPresenter.new(organisation)
    @type = params[:type].to_sym
    upload = CsvFileUpload.new(params[:organisation], :"activity_csv_#{@type}")
    @success = false
    is_oda = Activity::Import.is_oda_by_type(type: @type)

    if upload.valid?
      importer = Activity::Import.new(
        uploader: current_user,
        partner_organisation: organisation,
        report: nil,
        is_oda: is_oda
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

  def organisation
    @organisation ||= Organisation.find(params[:organisation_id])
  end
end
