# frozen_string_literal: true

class Staff::LevelBActivityUploadsController < Staff::BaseController
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

  private

  def csv_headers
    ["RODA ID"] + Activities::ImportFromCsv.level_b_column_headings
  end

  def organisation
    @organisation ||= Organisation.find(params[:organisation_id])
  end
end
